use axum::extract::{Query, State};
use axum::Json;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::broadcast;
use validator::Validate;

use crate::auth::extractor::AuthUser;
use crate::config::Config;
use crate::dto::practice::{
    AdaptiveQuestionResponse, GetQuestionsRequest, PracticeFeedbackResponse, PracticeSubmitRequest,
};
use crate::error::{ApiError, ApiResult};
use crate::error::ErrorResponse;
use crate::repository::question_repository::PgQuestionRepository;
use crate::repository::skill_repository::PgSkillRepository;
use crate::services::adaptive_engine::AdaptiveEngine;
use crate::state::RedisPool;
use crate::handlers::leaderboard::ConcreteLeaderboardService;

/// Concrete type alias for dependency injection
pub type ConcreteAdaptiveEngine = AdaptiveEngine<PgQuestionRepository, PgSkillRepository>;

// ─── GET /practice/questions ─────────────────────────────────────────────────

#[utoipa::path(get, path = "/api/v1/practice/questions", tag = "Practice", params(GetQuestionsRequest), responses((status = 200, description = "Adaptive questions", body = Vec<AdaptiveQuestionResponse>), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn get_questions(
    auth: AuthUser,
    State(engine): State<Arc<ConcreteAdaptiveEngine>>,
    State(pool): State<PgPool>,
    Query(params): Query<GetQuestionsRequest>,
) -> ApiResult<Json<Vec<AdaptiveQuestionResponse>>> {
    params
        .validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    let count = params.count.unwrap_or(5).clamp(1, 20);

    // Look up user's grade level from the database
    let grade_level: i32 = sqlx::query_scalar(
        "SELECT grade_level FROM users WHERE id = $1",
    )
    .bind(auth.user_id)
    .fetch_optional(&pool)
    .await?
    .unwrap_or(3); // default grade 3 if not set

    let questions = engine
        .get_adaptive_questions(auth.user_id, &params.topic, grade_level, count)
        .await?;

    tracing::debug!(
        "Served {} adaptive questions for user {} (topic={}, grade={})",
        questions.len(),
        auth.user_id,
        params.topic,
        grade_level
    );

    Ok(Json(questions))
}

// ─── POST /practice/submit ───────────────────────────────────────────────────

#[utoipa::path(post, path = "/api/v1/practice/submit", tag = "Practice", request_body = PracticeSubmitRequest, responses((status = 200, description = "Practice feedback", body = PracticeFeedbackResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn submit_practice(
    auth: AuthUser,
    State(engine): State<Arc<ConcreteAdaptiveEngine>>,
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
    State(config): State<Arc<Config>>,
    State(ws_sender): State<broadcast::Sender<String>>,
    State(leaderboard_service): State<Arc<ConcreteLeaderboardService>>,
    Json(body): Json<PracticeSubmitRequest>,
) -> ApiResult<Json<PracticeFeedbackResponse>> {
    // Delegate adaptive logic to the engine
    let feedback = engine.submit_answer(auth.user_id, &body).await?;

    // Map numeric difficulty to string for gamification integration
    let difficulty_str = match body.difficulty_level {
        1..=3 => "easy",
        4..=7 => "medium",
        _ => "hard",
    };

    // Record result in exercise_results (shared table with legacy exercises)
    sqlx::query(
        r#"
        INSERT INTO exercise_results (user_id, topic, difficulty, question_text, correct_answer, user_answer, is_correct, points_earned, time_taken_ms)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        "#,
    )
    .bind(auth.user_id)
    .bind(&body.topic)
    .bind(difficulty_str)
    .bind(&body.question_text)
    .bind(body.correct_answer)
    .bind(body.answer)
    .bind(feedback.is_correct)
    .bind(feedback.points_earned)
    .bind(body.time_taken_ms)
    .execute(&pool)
    .await?;

    // Update gamification pipeline (reuse existing helpers from exercise module)
    super::exercise::update_daily_progress(
        &pool,
        auth.user_id,
        feedback.is_correct,
        feedback.points_earned,
        body.time_taken_ms,
    )
    .await?;

    super::exercise::update_topic_mastery(&pool, auth.user_id, &body.topic, feedback.is_correct)
        .await?;

    super::exercise::update_leaderboard(&leaderboard_service, auth.user_id, feedback.points_earned).await?;

    let _ = super::exercise::check_and_unlock_achievements(
        &pool,
        &redis,
        auth.user_id,
        &ws_sender,
        &config,
    )
    .await;

    Ok(Json(feedback))
}
