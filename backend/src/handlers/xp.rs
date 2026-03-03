use std::sync::Arc;

use axum::extract::{Path, State};
use axum::Json;
#[allow(unused_imports)]
use uuid::Uuid;

use crate::auth::extractor::AuthUser;
use crate::dto::xp::{ThemeListResponse, ThemeResponse, XpProfileResponse};
use crate::error::ApiResult;
use crate::error::ErrorResponse;
use crate::services::xp_service::XpService;

pub type ConcreteXpService = XpService;

// ─── GET /xp/profile ────────────────────────────────────────────────────────

#[utoipa::path(get, path = "/api/v1/xp/profile", tag = "XP & Gamification", responses((status = 200, description = "XP profile", body = XpProfileResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn get_xp_profile(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
) -> ApiResult<Json<XpProfileResponse>> {
    let profile = xp_service.get_profile(auth.user_id).await?;
    Ok(Json(profile))
}

// ─── GET /xp/themes ─────────────────────────────────────────────────────────

#[utoipa::path(get, path = "/api/v1/xp/themes", tag = "XP & Gamification", responses((status = 200, description = "Available themes", body = ThemeListResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn get_themes(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
) -> ApiResult<Json<ThemeListResponse>> {
    let themes = xp_service.get_themes(auth.user_id).await?;
    Ok(Json(themes))
}

// ─── POST /xp/themes/:id/unlock ─────────────────────────────────────────────

#[utoipa::path(post, path = "/api/v1/xp/themes/{id}/unlock", tag = "XP & Gamification", params(("id" = Uuid, Path, description = "Theme ID")), responses((status = 200, description = "Theme unlocked", body = ThemeResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn unlock_theme(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
    Path(theme_id): Path<uuid::Uuid>,
) -> ApiResult<Json<ThemeResponse>> {
    let theme = xp_service.unlock_theme(auth.user_id, theme_id).await?;
    Ok(Json(theme))
}

// ─── PUT /xp/themes/:id/activate ────────────────────────────────────────────

#[utoipa::path(put, path = "/api/v1/xp/themes/{id}/activate", tag = "XP & Gamification", params(("id" = Uuid, Path, description = "Theme ID")), responses((status = 200, description = "Theme activated"), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn activate_theme(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
    Path(theme_id): Path<uuid::Uuid>,
) -> ApiResult<Json<serde_json::Value>> {
    xp_service.activate_theme(auth.user_id, theme_id).await?;
    Ok(Json(serde_json::json!({ "message": "Theme activated successfully" })))
}
