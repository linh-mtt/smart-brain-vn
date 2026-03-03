use std::sync::Arc;

use axum::extract::{Query, State};
use axum::Json;

use crate::auth::extractor::AuthUser;
use crate::dto::leaderboard::{LeaderboardQueryParams, LeaderboardResponse, MyRankDto};
use crate::error::ApiResult;
use crate::error::ErrorResponse;
use crate::repository::leaderboard_repository::PgLeaderboardRepository;
use crate::services::leaderboard_service::LeaderboardService;

/// Concrete type alias for dependency injection
pub type ConcreteLeaderboardService = LeaderboardService<PgLeaderboardRepository>;

// ─── GET /leaderboard ──────────────────────────────────────────────────────

#[utoipa::path(get, path = "/api/v1/leaderboard", tag = "Leaderboard", params(LeaderboardQueryParams), responses((status = 200, description = "Leaderboard entries", body = LeaderboardResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn get_leaderboard(
    auth: AuthUser,
    State(service): State<Arc<ConcreteLeaderboardService>>,
    Query(params): Query<LeaderboardQueryParams>,
) -> ApiResult<Json<LeaderboardResponse>> {
    let response = service.get_leaderboard(auth.user_id, &params).await?;
    Ok(Json(response))
}

// ─── GET /leaderboard/me ───────────────────────────────────────────────────

#[utoipa::path(get, path = "/api/v1/leaderboard/me", tag = "Leaderboard", params(LeaderboardQueryParams), responses((status = 200, description = "My rank", body = Option<MyRankDto>), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn get_my_rank(
    auth: AuthUser,
    State(service): State<Arc<ConcreteLeaderboardService>>,
    Query(params): Query<LeaderboardQueryParams>,
) -> ApiResult<Json<Option<MyRankDto>>> {
    let response = service.get_my_rank(auth.user_id, &params).await?;
    Ok(Json(response))
}
