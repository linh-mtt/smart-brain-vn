use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::models::user::UserRole;

/// Pure domain entity — no sqlx, no serde derives.
/// Represents a user in the business logic layer.
#[derive(Debug, Clone)]
pub struct DomainUser {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub password_hash: String,
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
