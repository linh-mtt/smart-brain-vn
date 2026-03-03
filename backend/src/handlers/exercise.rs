use axum::extract::{Query, State};
use axum::Json;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::broadcast;
use uuid::Uuid;
use validator::Validate;

use crate::auth::extractor::AuthUser;
use crate::config::Config;
use crate::error::{ApiError, ApiResult};
use crate::models::user::{
    AnswerFeedback, ExerciseResponse, GenerateExerciseRequest, PaginationParams,
    SubmitAnswerRequest,
};
use crate::error::ErrorResponse;
use crate::services::gamification;
use crate::services::math_engine::{self, Difficulty, MathTopic};
use crate::state::RedisPool;
use crate::ws::broadcast_event;
use crate::handlers::leaderboard::ConcreteLeaderboardService;

#[utoipa::path(post, path = "/api/v1/exercises/generate", tag = "Exercises", request_body = GenerateExerciseRequest, responses((status = 200, description = "Generated exercises", body = Vec<ExerciseResponse>), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn generate(
    auth: AuthUser,
    State(redis): State<RedisPool>,
    Json(body): Json<GenerateExerciseRequest>,
) -> ApiResult<Json<Vec<ExerciseResponse>>> {
    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    let topic = MathTopic::from_str_value(&body.topic)
        .ok_or_else(|| ApiError::BadRequest(format!("Invalid topic: {}. Use: addition, subtraction, multiplication, division", body.topic)))?;

    let difficulty = Difficulty::from_str_value(&body.difficulty)
        .ok_or_else(|| ApiError::BadRequest(format!("Invalid difficulty: {}. Use: easy, medium, hard", body.difficulty)))?;

    let count = body.count.clamp(1, 20);

    // Check cache first
    let cache_key = format!("{}:{}:{}:{}", auth.user_id, body.topic, body.difficulty, count);
    if let Ok(Some(cached)) = crate::services::cache::get_cached_problem_set(&redis, &cache_key).await {
        let responses: Vec<ExerciseResponse> = cached
            .into_iter()
            .map(|p| ExerciseResponse {
                id: p.id,
                question_text: p.question_text,
                options: p.options,
                difficulty: p.difficulty,
                topic: p.topic,
            })
            .collect();
        return Ok(Json(responses));
    }

    // Generate fresh problems
    let problems = math_engine::generate_problems(&topic, &difficulty, count);

    // Cache the problems for answer validation (5 minutes TTL)
    let _ = crate::services::cache::cache_problem_set(&redis, &cache_key, &problems, 300).await;

    // Also cache individual problems for submission lookup
    for problem in &problems {
        let individual_key = problem.id.to_string();
        let _ = crate::services::cache::cache_problem_set(
            &redis,
            &individual_key,
            &[problem.clone()],
            600,
        )
        .await;
    }

    let responses: Vec<ExerciseResponse> = problems
        .into_iter()
        .map(|p| ExerciseResponse {
            id: p.id,
            question_text: p.question_text,
            options: p.options,
            difficulty: p.difficulty,
            topic: p.topic,
        })
        .collect();

    tracing::debug!(
        "Generated {} problems for user {}",
        count,
        auth.user_id
    );

    Ok(Json(responses))
}

#[utoipa::path(post, path = "/api/v1/exercises/submit", tag = "Exercises", request_body = SubmitAnswerRequest, responses((status = 200, description = "Answer feedback", body = AnswerFeedback), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn submit(
    auth: AuthUser,
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
    State(config): State<Arc<Config>>,
    State(ws_sender): State<broadcast::Sender<String>>,
    State(leaderboard_service): State<Arc<ConcreteLeaderboardService>>,
    Json(body): Json<SubmitAnswerRequest>,
) -> ApiResult<Json<AnswerFeedback>> {
    // Look up the cached problem to validate the answer
    let individual_key = body.exercise_id.to_string();
    let cached_problems = crate::services::cache::get_cached_problem_set(&redis, &individual_key)
        .await?
        .ok_or_else(|| {
            ApiError::NotFound("Exercise not found or expired. Please generate new exercises.".to_string())
        })?;

    let problem = cached_problems
        .first()
        .ok_or_else(|| ApiError::InternalError("Cached problem is empty".to_string()))?;

    // Check answer (allow small floating point tolerance)
    let is_correct = (body.answer - problem.correct_answer).abs() < 0.01;

    // Get current streak (consecutive correct from most recent)
    let current_streak: i32 = sqlx::query_scalar(
        r#"
        WITH ranked AS (
            SELECT is_correct, ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
            FROM exercise_results WHERE user_id = $1
        )
        SELECT COALESCE(
            (SELECT COUNT(*)::int4 FROM ranked WHERE is_correct = true AND rn <= (
                SELECT COALESCE(MIN(rn) - 1, (SELECT COUNT(*) FROM ranked)) FROM ranked WHERE is_correct = false
            )),
            0
        )
        "#,
    )
    .bind(auth.user_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0);

    let streak_for_calc = if is_correct { current_streak } else { 0 };

    // Parse difficulty
    let difficulty = Difficulty::from_str_value(&problem.difficulty).unwrap_or(Difficulty::Easy);

    // Calculate points
    let points_earned = gamification::calculate_points(is_correct, &difficulty, streak_for_calc);

    // Record result in database
    sqlx::query(
        r#"
        INSERT INTO exercise_results (user_id, topic, difficulty, question_text, correct_answer, user_answer, is_correct, points_earned, time_taken_ms)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        "#,
    )
    .bind(auth.user_id)
    .bind(&problem.topic)
    .bind(&problem.difficulty)
    .bind(&problem.question_text)
    .bind(problem.correct_answer)
    .bind(body.answer)
    .bind(is_correct)
    .bind(points_earned)
    .bind(body.time_taken_ms)
    .execute(&pool)
    .await?;

    // Update daily progress
    update_daily_progress(&pool, auth.user_id, is_correct, points_earned, body.time_taken_ms).await?;

    // Update topic mastery
    update_topic_mastery(&pool, auth.user_id, &problem.topic, is_correct).await?;

    // Update leaderboard
    update_leaderboard(&leaderboard_service, auth.user_id, points_earned).await?;

    // Check achievements
    let _ = check_and_unlock_achievements(&pool, &redis, auth.user_id, &ws_sender, &config).await;

    // Broadcast streak update if applicable
    if is_correct && current_streak > 0 && current_streak % 5 == 0 {
        broadcast_event(
            &ws_sender,
            "streak_update",
            &auth.user_id.to_string(),
            serde_json::json!({ "streak": current_streak + 1 }),
            false,
        );
    }

    let feedback = AnswerFeedback {
        is_correct,
        correct_answer: problem.correct_answer,
        points_earned,
        explanation: problem.explanation.clone(),
    };

    Ok(Json(feedback))
}

#[utoipa::path(get, path = "/api/v1/exercises/history", tag = "Exercises", params(PaginationParams), responses((status = 200, description = "Exercise history"), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn history(
    auth: AuthUser,
    State(pool): State<PgPool>,
    Query(params): Query<PaginationParams>,
) -> ApiResult<Json<serde_json::Value>> {
    let offset = params.offset();
    let limit = params.per_page();

    let results = sqlx::query_as::<_, crate::models::user::RecentExercise>(
        r#"
        SELECT id, topic, difficulty, is_correct, points_earned, created_at
        FROM exercise_results
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
        "#,
    )
    .bind(auth.user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(&pool)
    .await?;

    let total: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM exercise_results WHERE user_id = $1")
        .bind(auth.user_id)
        .fetch_one(&pool)
        .await?;

    Ok(Json(serde_json::json!({
        "data": results,
        "total": total,
        "page": params.page.unwrap_or(1),
        "per_page": limit,
    })))
}

// ─── Internal Helpers ────────────────────────────────────────────────────────

pub(crate) async fn update_daily_progress(
    pool: &PgPool,
    user_id: Uuid,
    is_correct: bool,
    points: i32,
    time_ms: Option<i32>,
) -> ApiResult<()> {
    let correct_inc = if is_correct { 1 } else { 0 };
    let time_inc = time_ms.unwrap_or(0) as i64;

    // Calculate streak: check if user practiced yesterday
    let yesterday_practiced: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM daily_progress WHERE user_id = $1 AND date = CURRENT_DATE - INTERVAL '1 day')",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .unwrap_or(false);

    let yesterday_streak: i32 = if yesterday_practiced {
        sqlx::query_scalar(
            "SELECT COALESCE(streak_count, 0) FROM daily_progress WHERE user_id = $1 AND date = CURRENT_DATE - INTERVAL '1 day'",
        )
        .bind(user_id)
        .fetch_one(pool)
        .await
        .unwrap_or(0)
    } else {
        0
    };

    let new_streak = yesterday_streak + 1;

    sqlx::query(
        r#"
        INSERT INTO daily_progress (user_id, date, total_exercises, correct_count, total_points, total_time_ms, streak_count)
        VALUES ($1, CURRENT_DATE, 1, $2, $3, $4, $5)
        ON CONFLICT (user_id, date)
        DO UPDATE SET
            total_exercises = daily_progress.total_exercises + 1,
            correct_count = daily_progress.correct_count + $2,
            total_points = daily_progress.total_points + $3,
            total_time_ms = daily_progress.total_time_ms + $4,
            streak_count = GREATEST(daily_progress.streak_count, $5)
        "#,
    )
    .bind(user_id)
    .bind(correct_inc)
    .bind(points)
    .bind(time_inc)
    .bind(new_streak)
    .execute(pool)
    .await?;

    Ok(())
}

pub(crate) async fn update_topic_mastery(
    pool: &PgPool,
    user_id: Uuid,
    topic: &str,
    is_correct: bool,
) -> ApiResult<()> {
    let correct_inc = if is_correct { 1 } else { 0 };

    sqlx::query(
        r#"
        INSERT INTO topic_mastery (user_id, topic, total_answered, correct_count, mastery_score, last_practiced)
        VALUES ($1, $2, 1, $3, $3::float * 100.0, NOW())
        ON CONFLICT (user_id, topic)
        DO UPDATE SET
            total_answered = topic_mastery.total_answered + 1,
            correct_count = topic_mastery.correct_count + $3,
            mastery_score = ((topic_mastery.correct_count + $3)::float / (topic_mastery.total_answered + 1)::float) * 100.0,
            last_practiced = NOW()
        "#,
    )
    .bind(user_id)
    .bind(topic)
    .bind(correct_inc)
    .execute(pool)
    .await?;

    Ok(())
}

pub(crate) async fn update_leaderboard(
    service: &Arc<ConcreteLeaderboardService>,
    user_id: Uuid,
    points: i32,
) -> ApiResult<()> {
    service.update_points(user_id, points).await
}

pub(crate) async fn check_and_unlock_achievements(
    pool: &PgPool,
    _redis: &RedisPool,
    user_id: Uuid,
    ws_sender: &broadcast::Sender<String>,
    _config: &Config,
) -> ApiResult<()> {
    // Gather user stats
    let total_answered: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM exercise_results WHERE user_id = $1")
            .bind(user_id)
            .fetch_one(pool)
            .await?;

    let total_correct: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM exercise_results WHERE user_id = $1 AND is_correct = true")
            .bind(user_id)
            .fetch_one(pool)
            .await?;

    let total_points: i64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(points_earned), 0) FROM exercise_results WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await?;

    // Calculate current streak (consecutive correct answers)
    let current_streak: i32 = sqlx::query_scalar(
        r#"
        WITH ranked AS (
            SELECT is_correct, ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
            FROM exercise_results WHERE user_id = $1
        )
        SELECT COALESCE(
            (SELECT COUNT(*)::int4 FROM ranked WHERE is_correct = true AND rn <= (
                SELECT COALESCE(MIN(rn) - 1, (SELECT COUNT(*) FROM ranked)) FROM ranked WHERE is_correct = false
            )),
            0
        )
        "#,
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .unwrap_or(0);

    // Day streak
    let day_streak: i32 = sqlx::query_scalar(
        "SELECT COALESCE(MAX(streak_count), 0) FROM daily_progress WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .unwrap_or(0);

    // Topic-specific stats helper
    async fn fetch_topic_stats(pool: &PgPool, user_id: Uuid, topic: &str) -> (i64, i64) {
        let row: Option<(i64, i64)> = sqlx::query_as(
            "SELECT COALESCE(total_answered, 0)::int8, COALESCE(correct_count, 0)::int8 FROM topic_mastery WHERE user_id = $1 AND topic = $2",
        )
        .bind(user_id)
        .bind(topic)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();
        row.unwrap_or((0, 0))
    }

    let (addition_total, addition_correct) = fetch_topic_stats(pool, user_id, "addition").await;
    let (subtraction_total, subtraction_correct) = fetch_topic_stats(pool, user_id, "subtraction").await;
    let (multiplication_total, multiplication_correct) = fetch_topic_stats(pool, user_id, "multiplication").await;
    let (division_total, division_correct) = fetch_topic_stats(pool, user_id, "division").await;

    let (level, _, _) = gamification::calculate_level(total_points);

    let user_stats = gamification::UserStats {
        total_answered,
        total_correct,
        current_streak,
        longest_streak: current_streak,
        total_points,
        day_streak,
        level,
        addition_total,
        addition_correct,
        subtraction_total,
        subtraction_correct,
        multiplication_total,
        multiplication_correct,
        division_total,
        division_correct,
        fastest_five_ms: None,
        perfect_session: false,
        perfect_session_count: 0,
    };

    let potential_unlocks = gamification::check_achievements(&user_stats);

    for unlock in &potential_unlocks {
        // Check if already unlocked
        let already_unlocked: bool = sqlx::query_scalar(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM user_achievements ua
                JOIN achievements a ON ua.achievement_id = a.id
                WHERE ua.user_id = $1 AND a.name = $2
            )
            "#,
        )
        .bind(user_id)
        .bind(&unlock.achievement_name)
        .fetch_one(pool)
        .await
        .unwrap_or(true);

        if !already_unlocked {
            // Unlock achievement
            let achievement_id: Option<Uuid> = sqlx::query_scalar(
                "SELECT id FROM achievements WHERE name = $1",
            )
            .bind(&unlock.achievement_name)
            .fetch_optional(pool)
            .await?;

            if let Some(ach_id) = achievement_id {
                sqlx::query(
                    "INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
                )
                .bind(user_id)
                .bind(ach_id)
                .execute(pool)
                .await?;

                // Get achievement details for the broadcast
                let ach_description: Option<String> = sqlx::query_scalar(
                    "SELECT description FROM achievements WHERE id = $1",
                )
                .bind(ach_id)
                .fetch_optional(pool)
                .await?;

                broadcast_event(
                    ws_sender,
                    "achievement_unlocked",
                    &user_id.to_string(),
                    serde_json::json!({
                        "achievement_name": unlock.achievement_name,
                        "description": ach_description.unwrap_or_default(),
                    }),
                    false,
                );

                tracing::info!(
                    "Achievement '{}' unlocked for user {}",
                    unlock.achievement_name,
                    user_id
                );
            }
        }
    }

    Ok(())
}
