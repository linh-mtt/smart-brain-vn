use chrono::{DateTime, Utc};
use serde::Serialize;
use uuid::Uuid;

// ─── Theme Model ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct UnlockableTheme {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub emoji: String,
    pub required_level: i32,
    pub required_xp: i64,
    pub is_premium: bool,
    pub created_at: DateTime<Utc>,
}

// ─── User Theme (join table row) ────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct UserTheme {
    pub id: Uuid,
    pub user_id: Uuid,
    pub theme_id: Uuid,
    pub unlocked_at: DateTime<Utc>,
    pub is_active: bool,
}

// ─── Theme with unlock status (for list queries) ────────────────────────────

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct ThemeWithStatus {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub emoji: String,
    pub required_level: i32,
    pub required_xp: i64,
    pub is_premium: bool,
    pub is_unlocked: bool,
    pub is_active: bool,
}
