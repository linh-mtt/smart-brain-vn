use std::sync::Arc;

use axum::extract::{Query, State};
use axum::Json;

use crate::auth::extractor::AuthUser;
use crate::dto::leaderboard::{LeaderboardQueryParams, LeaderboardResponse, MyRankDto};
use crate::error::ApiResult;
use crate::repository::leaderboard_repository::PgLeaderboardRepository;
use crate::services::leaderboard_service::LeaderboardService;

/// Concrete type alias for dependency injection
pub type ConcreteLeaderboardService = LeaderboardService<PgLeaderboardRepository>;

// ─── GET /leaderboard ──────────────────────────────────────────────────────

pub async fn get_leaderboard(
    auth: AuthUser,
    State(service): State<Arc<ConcreteLeaderboardService>>,
    Query(params): Query<LeaderboardQueryParams>,
) -> ApiResult<Json<LeaderboardResponse>> {
    let response = service.get_leaderboard(auth.user_id, &params).await?;
    Ok(Json(response))
}

// ─── GET /leaderboard/me ───────────────────────────────────────────────────

pub async fn get_my_rank(
    auth: AuthUser,
    State(service): State<Arc<ConcreteLeaderboardService>>,
    Query(params): Query<LeaderboardQueryParams>,
) -> ApiResult<Json<Option<MyRankDto>>> {
    let response = service.get_my_rank(auth.user_id, &params).await?;
    Ok(Json(response))
}
