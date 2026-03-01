use axum::extract::{Path, State};
use axum::Json;
use sqlx::PgPool;

use crate::auth::extractor::AuthUser;
use crate::error::ApiResult;
use crate::models::user::{ProgressSummary, TopicProgressResponse};
use crate::services::gamification;

pub async fn summary(
    auth: AuthUser,
    State(pool): State<PgPool>,
) -> ApiResult<Json<ProgressSummary>> {
    let total_points: i64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(points_earned), 0) FROM exercise_results WHERE user_id = $1",
    )
    .bind(auth.user_id)
    .fetch_one(&pool)
    .await?;

    let total_exercises: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM exercise_results WHERE user_id = $1")
            .bind(auth.user_id)
            .fetch_one(&pool)
            .await?;

    let total_correct: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM exercise_results WHERE user_id = $1 AND is_correct = true",
    )
    .bind(auth.user_id)
    .fetch_one(&pool)
    .await?;

    let accuracy_rate = if total_exercises > 0 {
        (total_correct as f64 / total_exercises as f64) * 100.0
    } else {
        0.0
    };

    // Current streak (consecutive correct from most recent)
    let current_streak: i32 = sqlx::query_scalar(
        r#"
        WITH ranked AS (
            SELECT is_correct, ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
            FROM exercise_results WHERE user_id = $1
        )
        SELECT COUNT(*)::int4 FROM ranked WHERE is_correct = true AND rn <= (
            SELECT COALESCE(MIN(rn) - 1, COUNT(*)) FROM ranked WHERE is_correct = false
        )
        "#,
    )
    .bind(auth.user_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0);

    // Longest streak from daily_progress
    let longest_streak: i32 = sqlx::query_scalar(
        "SELECT COALESCE(MAX(streak_count), 0) FROM daily_progress WHERE user_id = $1",
    )
    .bind(auth.user_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0);

    let (level, _, xp_to_next) = gamification::calculate_level(total_points);

    Ok(Json(ProgressSummary {
        total_points,
        current_streak,
        longest_streak,
        total_exercises,
        accuracy_rate,
        level,
        xp_to_next_level: xp_to_next,
    }))
}

pub async fn topic_progress(
    auth: AuthUser,
    State(pool): State<PgPool>,
    Path(topic): Path<String>,
) -> ApiResult<Json<TopicProgressResponse>> {
    // Get mastery stats
    let mastery = sqlx::query_as::<_, (i32, i32, f64)>(
        r#"
        SELECT COALESCE(total_answered, 0), COALESCE(correct_count, 0), COALESCE(mastery_score, 0.0)
        FROM topic_mastery
        WHERE user_id = $1 AND topic = $2
        "#,
    )
    .bind(auth.user_id)
    .bind(&topic)
    .fetch_optional(&pool)
    .await?
    .unwrap_or((0, 0, 0.0));

    // Get recent 10 scores
    let recent_results: Vec<bool> = sqlx::query_scalar(
        r#"
        SELECT is_correct FROM exercise_results
        WHERE user_id = $1 AND topic = $2
        ORDER BY created_at DESC
        LIMIT 10
        "#,
    )
    .bind(auth.user_id)
    .bind(&topic)
    .fetch_all(&pool)
    .await?;

    Ok(Json(TopicProgressResponse {
        topic,
        mastery_score: mastery.2,
        total_answered: mastery.0,
        correct_count: mastery.1,
        recent_scores: recent_results,
    }))
}
