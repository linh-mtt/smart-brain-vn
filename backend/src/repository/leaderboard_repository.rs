use async_trait::async_trait;
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::leaderboard::LeaderboardEntry;
use crate::error::ApiResult;

// ─── Repository Trait ───────────────────────────────────────────────────────

#[async_trait]
pub trait LeaderboardRepository: Send + Sync {
    /// Get top entries for a given period with pagination
    async fn get_top_entries(
        &self,
        period: &str,
        limit: i64,
        offset: i64,
    ) -> ApiResult<Vec<LeaderboardEntry>>;

    /// Get a user's rank and points for a given period
    async fn get_user_rank(&self, user_id: Uuid, period: &str)
        -> ApiResult<Option<(i64, i64)>>;

    /// Get total count of entries for a given period
    async fn get_total_count(&self, period: &str) -> ApiResult<i64>;

    /// Update a user's points (increment) across all periods
    async fn update_points(&self, user_id: Uuid, points: i32) -> ApiResult<()>;

    /// Get all entries for a given period (for cache population).
    /// Returns (user_id_string, total_points) tuples.
    async fn get_all_entries_for_cache(
        &self,
        period: &str,
        limit: i64,
    ) -> ApiResult<Vec<(String, f64)>>;
}

// ─── PostgreSQL Implementation ──────────────────────────────────────────────

pub struct PgLeaderboardRepository {
    pool: PgPool,
}

impl PgLeaderboardRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

// ─── Internal Row Types ─────────────────────────────────────────────────────

#[derive(sqlx::FromRow)]
struct LeaderboardRow {
    user_id: Uuid,
    username: String,
    display_name: Option<String>,
    total_points: i64,
    rank: i64,
}

#[derive(sqlx::FromRow)]
struct UserRankRow {
    rank: i64,
    total_points: i64,
}

#[derive(sqlx::FromRow)]
struct CacheEntryRow {
    user_id: Uuid,
    total_points: i64,
}

fn row_to_entry(row: LeaderboardRow) -> LeaderboardEntry {
    LeaderboardEntry {
        user_id: row.user_id,
        username: row.username,
        display_name: row.display_name,
        total_points: row.total_points,
        rank: row.rank,
    }
}

#[async_trait]
impl LeaderboardRepository for PgLeaderboardRepository {
    async fn get_top_entries(
        &self,
        period: &str,
        limit: i64,
        offset: i64,
    ) -> ApiResult<Vec<LeaderboardEntry>> {
        let rows = sqlx::query_as::<_, LeaderboardRow>(
            r#"
            SELECT
                le.user_id,
                u.username,
                u.display_name,
                le.total_points::int8 as total_points,
                (ROW_NUMBER() OVER (ORDER BY le.total_points DESC))::int8 as rank
            FROM leaderboard_entries le
            JOIN users u ON le.user_id = u.id
            WHERE le.period = $1 AND u.is_active = true
            ORDER BY le.total_points DESC
            LIMIT $2 OFFSET $3
            "#,
        )
        .bind(period)
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_entry).collect())
    }

    async fn get_user_rank(
        &self,
        user_id: Uuid,
        period: &str,
    ) -> ApiResult<Option<(i64, i64)>> {
        let row = sqlx::query_as::<_, UserRankRow>(
            r#"
            SELECT rank, total_points FROM (
                SELECT
                    le.user_id,
                    le.total_points::int8 as total_points,
                    (ROW_NUMBER() OVER (ORDER BY le.total_points DESC))::int8 as rank
                FROM leaderboard_entries le
                JOIN users u ON le.user_id = u.id
                WHERE le.period = $1 AND u.is_active = true
            ) ranked
            WHERE user_id = $2
            "#,
        )
        .bind(period)
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| (r.rank, r.total_points)))
    }

    async fn get_total_count(&self, period: &str) -> ApiResult<i64> {
        let count: i64 = sqlx::query_scalar(
            r#"
            SELECT COUNT(*)
            FROM leaderboard_entries le
            JOIN users u ON le.user_id = u.id
            WHERE le.period = $1 AND u.is_active = true
            "#,
        )
        .bind(period)
        .fetch_one(&self.pool)
        .await?;

        Ok(count)
    }

    async fn update_points(&self, user_id: Uuid, points: i32) -> ApiResult<()> {
        if points <= 0 {
            return Ok(());
        }

        for period in &["daily", "weekly", "all_time"] {
            sqlx::query(
                r#"
                INSERT INTO leaderboard_entries (user_id, period, total_points, rank, updated_at)
                VALUES ($1, $2, $3, 0, NOW())
                ON CONFLICT (user_id, period)
                DO UPDATE SET
                    total_points = leaderboard_entries.total_points + $3,
                    updated_at = NOW()
                "#,
            )
            .bind(user_id)
            .bind(period)
            .bind(points)
            .execute(&self.pool)
            .await?;
        }

        Ok(())
    }

    async fn get_all_entries_for_cache(
        &self,
        period: &str,
        limit: i64,
    ) -> ApiResult<Vec<(String, f64)>> {
        let rows = sqlx::query_as::<_, CacheEntryRow>(
            r#"
            SELECT le.user_id, le.total_points::int8 as total_points
            FROM leaderboard_entries le
            JOIN users u ON le.user_id = u.id
            WHERE le.period = $1 AND u.is_active = true
            ORDER BY le.total_points DESC
            LIMIT $2
            "#,
        )
        .bind(period)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| (r.user_id.to_string(), r.total_points as f64))
            .collect())
    }
}
