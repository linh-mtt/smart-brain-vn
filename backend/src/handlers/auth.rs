use std::sync::Arc;

use axum::extract::State;
use axum::Json;

use crate::auth::extractor::AuthUser;
use crate::dto::auth::{AuthResponse, CreateUserRequest, LoginRequest, RefreshTokenRequest};
use crate::error::{ApiResult, ErrorResponse};
use crate::repository::token_repository::RedisTokenRepository;
use crate::repository::user_repository::PgUserRepository;
use crate::services::auth_service::AuthService;

/// Concrete type alias for dependency injection
pub type ConcreteAuthService = AuthService<PgUserRepository, RedisTokenRepository>;

#[utoipa::path(post, path = "/api/v1/auth/register", tag = "Authentication", request_body = CreateUserRequest, responses((status = 200, description = "User registered successfully", body = AuthResponse), (status = 409, description = "Email already exists", body = ErrorResponse)))]
pub async fn register(
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<CreateUserRequest>,
) -> ApiResult<Json<AuthResponse>> {
    let response = auth_service.register(&body).await?;
    Ok(Json(response))
}

#[utoipa::path(post, path = "/api/v1/auth/login", tag = "Authentication", request_body = LoginRequest, responses((status = 200, description = "Login successful", body = AuthResponse), (status = 401, description = "Invalid credentials", body = ErrorResponse)))]
pub async fn login(
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<LoginRequest>,
) -> ApiResult<Json<AuthResponse>> {
    let response = auth_service.login(&body).await?;
    Ok(Json(response))
}

#[utoipa::path(post, path = "/api/v1/auth/refresh", tag = "Authentication", request_body = RefreshTokenRequest, responses((status = 200, description = "Token refreshed", body = AuthResponse), (status = 401, description = "Invalid refresh token", body = ErrorResponse)))]
pub async fn refresh(
    State(auth_service): State<Arc<ConcreteAuthService>>,
    Json(body): Json<RefreshTokenRequest>,
) -> ApiResult<Json<AuthResponse>> {
    let response = auth_service.refresh(&body).await?;
    Ok(Json(response))
}

#[utoipa::path(post, path = "/api/v1/auth/logout", tag = "Authentication", request_body = RefreshTokenRequest, responses((status = 200, description = "Logged out"), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
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
