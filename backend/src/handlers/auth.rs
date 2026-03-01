use std::sync::Arc;

use axum::extract::State;
use axum::Json;

use crate::auth::extractor::AuthUser;
use crate::dto::auth::{AuthResponse, CreateUserRequest, LoginRequest, RefreshTokenRequest};
use crate::error::ApiResult;
use crate::repository::token_repository::RedisTokenRepository;
use crate::repository::user_repository::PgUserRepository;
use crate::services::auth_service::AuthService;

/// Concrete type alias for dependency injection
pub type ConcreteAuthService = AuthService<PgUserRepository, RedisTokenRepository>;

pub async fn register(
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<CreateUserRequest>,
) -> ApiResult<Json<AuthResponse>> {
    let response = auth_service.register(&body).await?;
    Ok(Json(response))
}

pub async fn login(
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<LoginRequest>,
) -> ApiResult<Json<AuthResponse>> {
    let response = auth_service.login(&body).await?;
    Ok(Json(response))
}

pub async fn refresh(
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<RefreshTokenRequest>,
) -> ApiResult<Json<AuthResponse>> {
    let response = auth_service.refresh(&body).await?;
    Ok(Json(response))
}

pub async fn logout(
    _auth: AuthUser,
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<RefreshTokenRequest>,
) -> ApiResult<Json<serde_json::Value>> {
    auth_service.logout(&body.refresh_token).await?;

    Ok(Json(serde_json::json!({
        "message": "Successfully logged out"
    })))
}
