use chrono::{Datelike, Utc};
use uuid::Uuid;

// ─── Leaderboard Period Enum ────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq)]
pub enum LeaderboardPeriod {
    Daily,
    Weekly,
    AllTime,
}

impl LeaderboardPeriod {
    pub fn as_str(&self) -> &'static str {
        match self {
            LeaderboardPeriod::Daily => "daily",
            LeaderboardPeriod::Weekly => "weekly",
            LeaderboardPeriod::AllTime => "all_time",
        }
    }

    pub fn from_str_value(s: &str) -> Option<Self> {
        match s {
            "daily" => Some(LeaderboardPeriod::Daily),
            "weekly" => Some(LeaderboardPeriod::Weekly),
            "all_time" => Some(LeaderboardPeriod::AllTime),
            _ => None,
        }
    }

    /// Cache key for Redis sorted set
    pub fn cache_key(&self) -> String {
        match self {
            LeaderboardPeriod::Daily => {
                let today = Utc::now().format("%Y-%m-%d");
                format!("leaderboard:daily:{}", today)
            }
            LeaderboardPeriod::Weekly => {
                let now = Utc::now();
                format!(
                    "leaderboard:weekly:{}W{:02}",
                    now.year(),
                    now.iso_week().week()
                )
            }
            LeaderboardPeriod::AllTime => "leaderboard:all_time".to_string(),
        }
    }

    /// TTL in seconds for cache expiry
    pub fn cache_ttl_seconds(&self) -> u64 {
        match self {
            LeaderboardPeriod::Daily => 3600,  // 1 hour
            LeaderboardPeriod::Weekly => 7200, // 2 hours
            LeaderboardPeriod::AllTime => 1800, // 30 minutes
        }
    }
}

// ─── Leaderboard Entry Entity ───────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct LeaderboardEntry {
    pub user_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub total_points: i64,
    pub rank: i64,
}

// ─── Pure Functions ─────────────────────────────────────────────────────────

/// Calculate page offset from page number and page size
pub fn calculate_offset(page: i64, per_page: i64) -> i64 {
    (page.max(1) - 1) * per_page
}

/// Clamp per_page to valid range
pub fn clamp_per_page(per_page: i64) -> i64 {
    per_page.clamp(1, 100)
}

// ─── Unit Tests ─────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_period_from_str() {
        assert_eq!(
            LeaderboardPeriod::from_str_value("daily"),
            Some(LeaderboardPeriod::Daily)
        );
        assert_eq!(
            LeaderboardPeriod::from_str_value("weekly"),
            Some(LeaderboardPeriod::Weekly)
        );
        assert_eq!(
            LeaderboardPeriod::from_str_value("all_time"),
            Some(LeaderboardPeriod::AllTime)
        );
        assert_eq!(LeaderboardPeriod::from_str_value("invalid"), None);
    }

    #[test]
    fn test_period_as_str() {
        assert_eq!(LeaderboardPeriod::Daily.as_str(), "daily");
        assert_eq!(LeaderboardPeriod::Weekly.as_str(), "weekly");
        assert_eq!(LeaderboardPeriod::AllTime.as_str(), "all_time");
    }

    #[test]
    fn test_cache_key_format() {
        let daily_key = LeaderboardPeriod::Daily.cache_key();
        assert!(daily_key.starts_with("leaderboard:daily:"));

        let weekly_key = LeaderboardPeriod::Weekly.cache_key();
        assert!(weekly_key.starts_with("leaderboard:weekly:"));
        assert!(weekly_key.contains('W'));

        let alltime_key = LeaderboardPeriod::AllTime.cache_key();
        assert_eq!(alltime_key, "leaderboard:all_time");
    }

    #[test]
    fn test_cache_ttl() {
        assert_eq!(LeaderboardPeriod::Daily.cache_ttl_seconds(), 3600);
        assert_eq!(LeaderboardPeriod::Weekly.cache_ttl_seconds(), 7200);
        assert_eq!(LeaderboardPeriod::AllTime.cache_ttl_seconds(), 1800);
    }

    #[test]
    fn test_calculate_offset() {
        assert_eq!(calculate_offset(1, 20), 0);
        assert_eq!(calculate_offset(2, 20), 20);
        assert_eq!(calculate_offset(3, 10), 20);
        assert_eq!(calculate_offset(0, 20), 0);
        assert_eq!(calculate_offset(-1, 20), 0);
    }

    #[test]
    fn test_clamp_per_page() {
        assert_eq!(clamp_per_page(20), 20);
        assert_eq!(clamp_per_page(0), 1);
        assert_eq!(clamp_per_page(-5), 1);
        assert_eq!(clamp_per_page(200), 100);
        assert_eq!(clamp_per_page(50), 50);
    }
}
