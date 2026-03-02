use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ─── XP Profile Response ────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct XpProfileResponse {
    pub user_id: Uuid,
    pub total_xp: i64,
    pub current_level: i32,
    pub xp_in_current_level: i64,
    pub xp_for_next_level: i64,
    pub xp_progress_percent: f64,
    pub unlocked_achievements: Vec<UnlockedAchievementDto>,
    pub active_theme: Option<ThemeResponse>,
}

// ─── XP Award Result ────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Clone)]
pub struct XpAwardResponse {
    pub xp_awarded: i32,
    pub total_xp: i64,
    pub previous_level: i32,
    pub current_level: i32,
    pub leveled_up: bool,
    pub xp_in_current_level: i64,
    pub xp_for_next_level: i64,
    pub newly_unlocked_achievements: Vec<UnlockedAchievementDto>,
}

// ─── Achievement DTO ────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Clone)]
pub struct UnlockedAchievementDto {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub emoji: String,
    pub reward_points: i32,
    pub unlocked_at: DateTime<Utc>,
}

// ─── Theme Response ─────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Clone)]
pub struct ThemeResponse {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub emoji: String,
    pub required_level: i32,
    pub required_xp: i64,
    pub is_premium: bool,
    pub is_unlocked: bool,
    pub is_active: bool,
    pub can_unlock: bool,
}

// ─── Theme List Response ────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct ThemeListResponse {
    pub themes: Vec<ThemeResponse>,
    pub active_theme_id: Option<Uuid>,
}

// ─── Activate Theme Request ─────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
pub struct ActivateThemeRequest {
    pub theme_id: Uuid,
}
