use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;
use utoipa::ToSchema;

use crate::domain::user::DomainUser;
use crate::models::user::UserRole;

// ─── Request DTOs ────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateUserRequest {
    #[validate(email(message = "Invalid email address"))]
    pub email: String,

    #[validate(length(min = 3, max = 50, message = "Username must be 3-50 characters"))]
    pub username: String,

    #[validate(length(min = 8, max = 128, message = "Password must be 8-128 characters"))]
    pub password: String,

    #[validate(length(max = 255, message = "Display name too long"))]
    pub display_name: Option<String>,

    #[validate(range(min = 1, max = 6, message = "Grade level must be 1-6"))]
    pub grade_level: Option<i32>,

    #[validate(range(min = 4, max = 18, message = "Age must be 4-18"))]
    pub age: Option<i32>,

    pub role: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct LoginRequest {
    #[validate(email(message = "Invalid email address"))]
    pub email: String,

    #[validate(length(min = 1, message = "Password is required"))]
    pub password: String,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

// ─── Response DTOs ───────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub grade_level: i32,
    pub age: Option<i32>,
    pub role: UserRole,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub total_xp: i64,
    pub current_level: i32,
}

impl From<DomainUser> for UserResponse {
    fn from(user: DomainUser) -> Self {
        UserResponse {
            id: user.id,
            email: user.email,
            username: user.username,
            display_name: user.display_name,
            avatar_url: user.avatar_url,
            grade_level: user.grade_level,
            age: user.age,
            role: user.role,
            is_active: user.is_active,
            created_at: user.created_at,
            updated_at: user.updated_at,
            total_xp: user.total_xp,
            current_level: user.current_level,
        }
    }
}

// Conversion from sqlx model — used by handlers that still query directly (e.g. user.rs)
impl From<crate::models::user::User> for UserResponse {
    fn from(user: crate::models::user::User) -> Self {
        UserResponse {
            id: user.id,
            email: user.email,
            username: user.username,
            display_name: user.display_name,
            avatar_url: user.avatar_url,
            grade_level: user.grade_level,
            age: user.age,
            role: user.role,
            is_active: user.is_active,
            created_at: user.created_at,
            updated_at: user.updated_at,
            total_xp: user.total_xp,
            current_level: user.current_level,
        }
    }
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AuthResponse {
    pub user: UserResponse,
    pub access_token: String,
    pub refresh_token: String,
}

// ─── JWT Claims ──────────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct TokenClaims {
    pub sub: String,
    pub email: String,
    pub role: String,
    pub exp: usize,
    pub iat: usize,
}
