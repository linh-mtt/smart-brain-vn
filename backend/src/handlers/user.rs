use axum::extract::State;
use axum::Json;
use sqlx::PgPool;
use validator::Validate;

use crate::auth::extractor::AuthUser;
use crate::error::{ApiError, ApiResult};
use crate::dto::auth::UserResponse;
use crate::models::user::{UpdateProfileRequest, User};
use crate::error::ErrorResponse;

#[utoipa::path(get, path = "/api/v1/users/me", tag = "Users", responses((status = 200, description = "Current user profile", body = UserResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn get_me(
    auth: AuthUser,
    State(pool): State<PgPool>,
) -> ApiResult<Json<UserResponse>> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(auth.user_id)
        .fetch_optional(&pool)
        .await?
        .ok_or(ApiError::NotFound("User not found".to_string()))?;

    Ok(Json(UserResponse::from(user)))
}

#[utoipa::path(put, path = "/api/v1/users/me", tag = "Users", request_body = UpdateProfileRequest, responses((status = 200, description = "Profile updated", body = UserResponse), (status = 401, description = "Unauthorized", body = ErrorResponse)), security(("bearer_jwt" = [])))]
pub async fn update_me(
    auth: AuthUser,
    State(pool): State<PgPool>,
    Json(body): Json<UpdateProfileRequest>,
) -> ApiResult<Json<UserResponse>> {
    body.validate()
        .map_err(|e| ApiError::ValidationError(e.to_string()))?;

    let user = sqlx::query_as::<_, User>(
        r#"
        UPDATE users
        SET display_name = COALESCE($2, display_name),
            avatar_url = COALESCE($3, avatar_url),
            grade_level = COALESCE($4, grade_level),
            age = COALESCE($5, age),
            updated_at = NOW()
        WHERE id = $1
        RETURNING *
        "#,
    )
    .bind(auth.user_id)
    .bind(&body.display_name)
    .bind(&body.avatar_url)
    .bind(body.grade_level)
    .bind(body.age)
    .fetch_optional(&pool)
    .await?
    .ok_or(ApiError::NotFound("User not found".to_string()))?;

    tracing::info!("Profile updated for user: {}", user.email);

    Ok(Json(UserResponse::from(user)))
}
