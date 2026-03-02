use std::sync::Arc;

use axum::extract::{Path, State};
use axum::Json;

use crate::auth::extractor::AuthUser;
use crate::dto::xp::{ThemeListResponse, ThemeResponse, XpProfileResponse};
use crate::error::ApiResult;
use crate::services::xp_service::XpService;

pub type ConcreteXpService = XpService;

// ─── GET /xp/profile ────────────────────────────────────────────────────────

pub async fn get_xp_profile(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
) -> ApiResult<Json<XpProfileResponse>> {
    let profile = xp_service.get_profile(auth.user_id).await?;
    Ok(Json(profile))
}

// ─── GET /xp/themes ─────────────────────────────────────────────────────────

pub async fn get_themes(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
) -> ApiResult<Json<ThemeListResponse>> {
    let themes = xp_service.get_themes(auth.user_id).await?;
    Ok(Json(themes))
}

// ─── POST /xp/themes/:id/unlock ─────────────────────────────────────────────

pub async fn unlock_theme(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
    Path(theme_id): Path<uuid::Uuid>,
) -> ApiResult<Json<ThemeResponse>> {
    let theme = xp_service.unlock_theme(auth.user_id, theme_id).await?;
    Ok(Json(theme))
}

// ─── PUT /xp/themes/:id/activate ────────────────────────────────────────────

pub async fn activate_theme(
    auth: AuthUser,
    State(xp_service): State<Arc<ConcreteXpService>>,
    Path(theme_id): Path<uuid::Uuid>,
) -> ApiResult<Json<serde_json::Value>> {
    xp_service.activate_theme(auth.user_id, theme_id).await?;
    Ok(Json(serde_json::json!({ "message": "Theme activated successfully" })))
}
