use axum::extract::{Path, State};
use axum::Json;
use sqlx::PgPool;
use std::sync::Arc;
use tokio::sync::broadcast;
use uuid::Uuid;
use validator::Validate;

use crate::auth::extractor::AuthUser;
use crate::config::Config;
use crate::dto::session::{
    SessionResultResponse, SessionSubmitRequest, SessionSubmitResponse, StartSessionRequest,
    StartSessionResponse,
};
use crate::error::{ApiError, ApiResult};
use crate::repository::question_repository::PgQuestionRepository;
use crate::repository::session_repository::PgSessionRepository;
use crate::repository::skill_repository::PgSkillRepository;
use crate::services::session_service::SessionService;
use crate::state::RedisPool;
use crate::handlers::leaderboard::ConcreteLeaderboardService;

/// Concrete type alias for dependency injection
pub type ConcreteSessionService =
    SessionService<PgSessionRepository, PgQuestionRepository, PgSkillRepository>;

// ─── POST /practice/start ───────────────────────────────────────────────────

pub async fn start_session(
    auth: AuthUser,
    State(service): State<Arc<ConcreteSessionService>>,
    State(pool): State<PgPool>,
    Json(body): Json<StartSessionRequest>,
) -> ApiResult<Json<StartSessionResponse>> {
    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    let question_count = body.question_count.unwrap_or(5).clamp(1, 20);

    // Look up user's grade level from the database
    let grade_level: i32 =
        sqlx::query_scalar("SELECT grade_level FROM users WHERE id = $1")
            .bind(auth.user_id)
            .fetch_optional(&pool)
            .await?
            .unwrap_or(3);

    let response = service
        .start_session(auth.user_id, &body.topic, grade_level, question_count)
        .await?;

    tracing::info!(
        "User {} started practice session {} (topic={}, questions={})",
        auth.user_id,
        response.session_id,
        body.topic,
        question_count
    );

    Ok(Json(response))
}

// ─── POST /practice/answer ──────────────────────────────────────────────────

pub async fn submit_answer(
    auth: AuthUser,
    State(service): State<Arc<ConcreteSessionService>>,
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
    State(config): State<Arc<Config>>,
    State(ws_sender): State<broadcast::Sender<String>>,
    State(leaderboard_service): State<Arc<ConcreteLeaderboardService>>,
    Json(body): Json<SessionSubmitRequest>,
) -> ApiResult<Json<SessionSubmitResponse>> {
    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    // Delegate session logic (combo, result recording, adaptive updates) to the service
    let response = service
        .submit_answer(
            auth.user_id,
            body.session_id,
            body.question_id,
            &body.topic,
            body.difficulty_level,
            &body.question_text,
            body.correct_answer,
            body.answer,
            body.time_taken_ms,
        )
        .await?;

    // ── Gamification integration (shared with legacy exercise pipeline) ──────

    let difficulty_str = match body.difficulty_level {
        1..=3 => "easy",
        4..=7 => "medium",
        _ => "hard",
    };

    // Record result in exercise_results (shared table for unified analytics)
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
    .bind(response.is_correct)
    .bind(response.points_earned)
    .bind(body.time_taken_ms)
    .execute(&pool)
    .await?;

    // Update gamification pipeline (reuse existing helpers from exercise module)
    super::exercise::update_daily_progress(
        &pool,
        auth.user_id,
        response.is_correct,
        response.points_earned,
        body.time_taken_ms,
    )
    .await?;

    super::exercise::update_topic_mastery(&pool, auth.user_id, &body.topic, response.is_correct)
        .await?;

    super::exercise::update_leaderboard(&leaderboard_service, auth.user_id, response.points_earned).await?;

    let _ = super::exercise::check_and_unlock_achievements(
        &pool,
        &redis,
        auth.user_id,
        &ws_sender,
        &config,
    )
    .await;

    Ok(Json(response))
}

// ─── GET /practice/result/:id ───────────────────────────────────────────────

pub async fn get_result(
    auth: AuthUser,
    State(service): State<Arc<ConcreteSessionService>>,
    Path(session_id): Path<Uuid>,
) -> ApiResult<Json<SessionResultResponse>> {
    let response = service.get_result(auth.user_id, session_id).await?;

    tracing::debug!(
        "User {} fetched result for session {} (accuracy={:.1}%)",
        auth.user_id,
        session_id,
        response.accuracy * 100.0
    );

    Ok(Json(response))
}
