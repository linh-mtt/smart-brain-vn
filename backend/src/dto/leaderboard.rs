use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ─── Request DTOs ───────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct LeaderboardQueryParams {
    /// Period filter: daily, weekly, all_time (default: all_time)
    pub period: Option<String>,
    /// Page number, 1-indexed (default: 1)
    pub page: Option<i64>,
    /// Results per page, 1-100 (default: 20)
    pub per_page: Option<i64>,
}

// ─── Response DTOs ──────────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct LeaderboardResponse {
    pub entries: Vec<LeaderboardEntryDto>,
    pub total_count: i64,
    pub page: i64,
    pub per_page: i64,
    pub period: String,
    /// The requesting user's rank in this period (None if unranked)
    pub my_rank: Option<MyRankDto>,
}

#[derive(Debug, Serialize)]
pub struct LeaderboardEntryDto {
    pub rank: i64,
    pub user_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub total_points: i64,
}

#[derive(Debug, Serialize)]
pub struct MyRankDto {
    pub rank: i64,
    pub total_points: i64,
}
