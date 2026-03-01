use std::sync::Arc;

use axum::extract::FromRequestParts;
use axum::http::request::Parts;

use crate::config::Config;
use crate::error::ApiError;
use crate::models::user::UserRole;
use crate::state::AppState;
use uuid::Uuid;

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct AuthUser {
    pub user_id: Uuid,
    pub email: String,
    pub role: UserRole,
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let config: &Arc<Config> = &state.config;

        let auth_header = parts
            .headers
            .get("Authorization")
            .and_then(|value| value.to_str().ok())
            .ok_or(ApiError::Unauthorized)?;

        let token = auth_header
            .strip_prefix("Bearer ")
            .ok_or(ApiError::Unauthorized)?;

        let claims = crate::auth::jwt::decode_token(token, &config.jwt_secret)
            .map_err(|_| ApiError::Unauthorized)?;

        let user_id = Uuid::parse_str(&claims.sub)
            .map_err(|_| ApiError::Unauthorized)?;

        let role = UserRole::from_str_value(&claims.role);

        Ok(AuthUser {
            user_id,
            email: claims.email,
            role,
        })
    }
}
