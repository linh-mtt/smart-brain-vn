use std::sync::Arc;

use redis::AsyncCommands;
use uuid::Uuid;

use crate::config::Config;
use crate::domain::leaderboard::{
    self, LeaderboardPeriod,
};
use crate::dto::leaderboard::{
    LeaderboardEntryDto, LeaderboardQueryParams, LeaderboardResponse, MyRankDto,
};
use crate::error::{ApiError, ApiResult};
use crate::repository::leaderboard_repository::LeaderboardRepository;
use crate::state::RedisPool;

// ─── Leaderboard Service ────────────────────────────────────────────────────

pub struct LeaderboardService<R: LeaderboardRepository> {
    repo: Arc<R>,
    redis: RedisPool,
    #[allow(dead_code)]
    config: Arc<Config>,
}

impl<R: LeaderboardRepository> LeaderboardService<R> {
    pub fn new(repo: Arc<R>, redis: RedisPool, config: Arc<Config>) -> Self {
        Self {
            repo,
            redis,
            config,
        }
    }

    /// Get paginated leaderboard with the requesting user's rank included.
    ///
    /// Strategy: DB for paginated entries (needs username JOIN), Redis for user rank lookup.
    pub async fn get_leaderboard(
        &self,
        user_id: Uuid,
        params: &LeaderboardQueryParams,
    ) -> ApiResult<LeaderboardResponse> {
        let period = params
            .period
            .as_deref()
            .and_then(LeaderboardPeriod::from_str_value)
            .unwrap_or(LeaderboardPeriod::AllTime);

        let per_page = leaderboard::clamp_per_page(params.per_page.unwrap_or(20));
        let page = params.page.unwrap_or(1).max(1);
        let offset = leaderboard::calculate_offset(page, per_page);

        // Fetch paginated entries from DB (needs username JOIN)
        let entries = self
            .repo
            .get_top_entries(period.as_str(), per_page, offset)
            .await?;

        let total_count = self.repo.get_total_count(period.as_str()).await?;

        // Try to get user's rank from Redis cache first, fall back to DB
        let my_rank = self.get_user_rank(user_id, &period).await?;

        let entry_dtos: Vec<LeaderboardEntryDto> = entries
            .into_iter()
            .map(|e| LeaderboardEntryDto {
                rank: e.rank,
                user_id: e.user_id,
                username: e.username,
                display_name: e.display_name,
                total_points: e.total_points,
            })
            .collect();

        Ok(LeaderboardResponse {
            entries: entry_dtos,
            total_count,
            page,
            per_page,
            period: period.as_str().to_string(),
            my_rank,
        })
    }

    /// Get the requesting user's rank and points for a specific period.
    ///
    /// Cache-first: check Redis sorted set, fall back to DB subquery.
    pub async fn get_my_rank(
        &self,
        user_id: Uuid,
        params: &LeaderboardQueryParams,
    ) -> ApiResult<Option<MyRankDto>> {
        let period = params
            .period
            .as_deref()
            .and_then(LeaderboardPeriod::from_str_value)
            .unwrap_or(LeaderboardPeriod::AllTime);

        self.get_user_rank(user_id, &period).await
    }

    /// Update a user's points across all leaderboard periods.
    ///
    /// Writes to DB first (source of truth), then best-effort updates Redis sorted sets.
    pub async fn update_points(&self, user_id: Uuid, points: i32) -> ApiResult<()> {
        if points <= 0 {
            return Ok(());
        }

        // 1. Write to DB (source of truth)
        self.repo.update_points(user_id, points).await?;

        // 2. Best-effort update Redis sorted sets (ZINCRBY for atomic increment)
        let periods = [
            LeaderboardPeriod::Daily,
            LeaderboardPeriod::Weekly,
            LeaderboardPeriod::AllTime,
        ];

        let member = user_id.to_string();

        for period in &periods {
            let cache_key = period.cache_key();
            if let Err(e) = self.zincrby_cached(&cache_key, &member, points as f64, period).await {
                tracing::warn!(
                    "Failed to update Redis leaderboard cache for {}: {:?}",
                    cache_key,
                    e
                );
                // Non-fatal: DB is source of truth
            }
        }

        Ok(())
    }

    // ─── Private Helpers ─────────────────────────────────────────────────────

    /// Get a user's rank from Redis cache, falling back to DB.
    async fn get_user_rank(
        &self,
        user_id: Uuid,
        period: &LeaderboardPeriod,
    ) -> ApiResult<Option<MyRankDto>> {
        let cache_key = period.cache_key();
        let member = user_id.to_string();

        // Try Redis first
        if let Some(dto) = self.get_user_rank_cached(&cache_key, &member).await {
            return Ok(Some(dto));
        }

        // Fall back to DB
        match self.repo.get_user_rank(user_id, period.as_str()).await? {
            Some((rank, total_points)) => Ok(Some(MyRankDto {
                rank,
                total_points,
            })),
            None => Ok(None),
        }
    }

    /// Try to get user's rank and score from a Redis sorted set.
    /// Returns None if cache is empty or user not in set (non-fatal).
    async fn get_user_rank_cached(&self, cache_key: &str, member: &str) -> Option<MyRankDto> {
        let mut conn = self.redis.get().await.ok()?;

        // Check if sorted set has entries (cache populated)
        let size: usize = conn.zcard(cache_key).await.ok()?;
        if size == 0 {
            return None;
        }

        // ZREVRANK returns 0-indexed rank
        let rank: Option<i64> = conn.zrevrank(cache_key, member).await.ok()?;
        let rank = rank?; // None means user not in the set

        let score: Option<f64> = conn.zscore(cache_key, member).await.ok()?;
        let total_points = score.unwrap_or(0.0) as i64;

        Some(MyRankDto {
            rank: rank + 1, // Convert 0-indexed to 1-indexed
            total_points,
        })
    }

    /// Atomically increment a user's score in a Redis sorted set.
    /// If the sorted set doesn't exist yet (cold cache), populate it from DB
    /// (which already has the latest data) and skip ZINCRBY to avoid double-counting.
    async fn zincrby_cached(
        &self,
        cache_key: &str,
        member: &str,
        increment: f64,
        period: &LeaderboardPeriod,
    ) -> ApiResult<()> {
        let mut conn = self.redis.get().await.map_err(|e| {
            tracing::error!("Failed to get Redis connection: {:?}", e);
            ApiError::InternalError("Cache connection error".to_string())
        })?;

        // Check if sorted set exists
        let size: usize = conn.zcard(cache_key).await?;

        if size == 0 {
            // Cold cache — populate from DB which already has the latest data
            // (repo.update_points runs before this). Skip ZINCRBY to avoid double-counting.
            self.populate_cache(cache_key, period).await?;
            return Ok(());
        }

        // ZINCRBY — atomically increment (creates member if absent)
        redis::cmd("ZINCRBY")
            .arg(cache_key)
            .arg(increment)
            .arg(member)
            .query_async::<f64>(&mut *conn)
            .await?;

        Ok(())
    }

    /// Populate a Redis sorted set from DB entries using a pipeline.
    /// DEL + bulk ZADD + EXPIRE in one round-trip.
    async fn populate_cache(
        &self,
        cache_key: &str,
        period: &LeaderboardPeriod,
    ) -> ApiResult<()> {
        let entries = self
            .repo
            .get_all_entries_for_cache(period.as_str(), 1000)
            .await?;

        if entries.is_empty() {
            return Ok(());
        }

        let mut conn = self.redis.get().await.map_err(|e| {
            tracing::error!("Failed to get Redis connection: {:?}", e);
            ApiError::InternalError("Cache connection error".to_string())
        })?;

        let ttl = period.cache_ttl_seconds() as i64;

        // Build pipeline: DEL old set, bulk ZADD, set EXPIRE
        let mut pipe = redis::pipe();
        pipe.del(cache_key).ignore();

        for (member, score) in &entries {
            pipe.zadd(cache_key, member.as_str(), *score).ignore();
        }

        pipe.expire(cache_key, ttl).ignore();

        pipe.query_async::<()>(&mut *conn).await?;

        tracing::debug!(
            "Populated leaderboard cache '{}' with {} entries (TTL={}s)",
            cache_key,
            entries.len(),
            ttl
        );

        Ok(())
    }
}
