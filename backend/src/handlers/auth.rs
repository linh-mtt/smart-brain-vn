use axum::extract::State;
use axum::Json;
use sqlx::PgPool;
use std::sync::Arc;
use validator::Validate;

use crate::auth::extractor::AuthUser;
use crate::auth::{create_access_token, create_refresh_token, hash_password, verify_password};
use crate::config::Config;
use crate::error::{ApiError, ApiResult};
use crate::models::user::{
    AuthResponse, CreateUserRequest, LoginRequest, RefreshTokenRequest, User, UserResponse,
    UserRole,
};
use crate::services::cache;
use crate::state::RedisPool;

pub async fn register(
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
    State(config): State<Arc<Config>>,
    Json(body): Json<CreateUserRequest>,
) -> ApiResult<Json<AuthResponse>> {
    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    // Check duplicate email
    let existing_email = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)"
    )
    .bind(&body.email)
    .fetch_one(&pool)
    .await?;

    if existing_email {
        return Err(ApiError::Conflict(
            "A user with this email already exists".to_string(),
        ));
    }

    // Check duplicate username
    let existing_username = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)"
    )
    .bind(&body.username)
    .fetch_one(&pool)
    .await?;

    if existing_username {
        return Err(ApiError::Conflict(
            "This username is already taken".to_string(),
        ));
    }

    // Hash password
    let password_hash = hash_password(&body.password)?;

    let role = body
        .role
        .as_deref()
        .map(UserRole::from_str_value)
        .unwrap_or(UserRole::Student);

    let grade_level = body.grade_level.unwrap_or(1);

    // Insert user
    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (email, username, password_hash, display_name, grade_level, age, role)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
        "#,
    )
    .bind(&body.email)
    .bind(&body.username)
    .bind(&password_hash)
    .bind(&body.display_name)
    .bind(grade_level)
    .bind(body.age)
    .bind(&role)
    .fetch_one(&pool)
    .await?;

    tracing::info!("New user registered: {} ({})", user.username, user.email);

    // Generate tokens
    let access_token = create_access_token(&user, &config)?;
    let refresh_token = create_refresh_token(&user, &config)?;

    // Store refresh token in Redis
    let refresh_ttl = config.jwt_refresh_expires_in.as_secs();
    cache::store_refresh_token(&redis, user.id, &refresh_token, refresh_ttl).await?;

    Ok(Json(AuthResponse {
        user: UserResponse::from(user),
        access_token,
        refresh_token,
    }))
}

pub async fn login(
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
    State(config): State<Arc<Config>>,
    Json(body): Json<LoginRequest>,
) -> ApiResult<Json<AuthResponse>> {
    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    // Find user by email
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1 AND is_active = true")
        .bind(&body.email)
        .fetch_optional(&pool)
        .await?
        .ok_or(ApiError::Unauthorized)?;

    // Verify password
    let is_valid = verify_password(&body.password, &user.password_hash)?;
    if !is_valid {
        return Err(ApiError::Unauthorized);
    }

    tracing::info!("User logged in: {} ({})", user.username, user.email);

    // Generate tokens
    let access_token = create_access_token(&user, &config)?;
    let refresh_token = create_refresh_token(&user, &config)?;

    // Store refresh token in Redis with 7d TTL
    let refresh_ttl = config.jwt_refresh_expires_in.as_secs();
    cache::store_refresh_token(&redis, user.id, &refresh_token, refresh_ttl).await?;

    Ok(Json(AuthResponse {
        user: UserResponse::from(user),
        access_token,
        refresh_token,
    }))
}

pub async fn refresh(
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
    State(config): State<Arc<Config>>,
    Json(body): Json<RefreshTokenRequest>,
) -> ApiResult<Json<AuthResponse>> {
    // Validate refresh token exists in Redis
    let user_id = cache::get_refresh_token(&redis, &body.refresh_token)
        .await?
        .ok_or(ApiError::Unauthorized)?;

    // Delete old refresh token (rotation)
    cache::delete_refresh_token(&redis, &body.refresh_token).await?;

    // Fetch user from database
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1 AND is_active = true")
        .bind(user_id)
        .fetch_optional(&pool)
        .await?
        .ok_or(ApiError::Unauthorized)?;

    // Generate new token pair
    let access_token = create_access_token(&user, &config)?;
    let refresh_token = create_refresh_token(&user, &config)?;

    // Store new refresh token
    let refresh_ttl = config.jwt_refresh_expires_in.as_secs();
    cache::store_refresh_token(&redis, user.id, &refresh_token, refresh_ttl).await?;

    tracing::debug!("Token refreshed for user: {}", user.email);

    Ok(Json(AuthResponse {
        user: UserResponse::from(user),
        access_token,
        refresh_token,
    }))
}

pub async fn logout(
    _auth: AuthUser,
    State(redis): State<RedisPool>,
    Json(body): Json<RefreshTokenRequest>,
) -> ApiResult<Json<serde_json::Value>> {
    cache::delete_refresh_token(&redis, &body.refresh_token).await?;

    tracing::debug!("User logged out, refresh token deleted");

    Ok(Json(serde_json::json!({
        "message": "Successfully logged out"
    })))
}
