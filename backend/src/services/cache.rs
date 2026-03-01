use redis::AsyncCommands;
use uuid::Uuid;

use crate::error::{ApiError, ApiResult};
use crate::services::math_engine::MathProblem;
use crate::state::RedisPool;

pub async fn store_refresh_token(
    pool: &RedisPool,
    user_id: Uuid,
    token: &str,
    ttl_seconds: u64,
) -> ApiResult<()> {
    let mut conn = pool.get().await.map_err(|e| {
        tracing::error!("Failed to get Redis connection: {:?}", e);
        ApiError::InternalError("Cache connection error".to_string())
    })?;

    let key = format!("refresh_token:{}", token);
    let _: () = conn.set_ex(&key, user_id.to_string(), ttl_seconds).await?;

    tracing::debug!("Stored refresh token for user {}", user_id);
    Ok(())
}

pub async fn get_refresh_token(pool: &RedisPool, token: &str) -> ApiResult<Option<Uuid>> {
    let mut conn = pool.get().await.map_err(|e| {
        tracing::error!("Failed to get Redis connection: {:?}", e);
        ApiError::InternalError("Cache connection error".to_string())
    })?;

    let key = format!("refresh_token:{}", token);
    let result: Option<String> = conn.get(&key).await?;

    match result {
        Some(user_id_str) => {
            let user_id = Uuid::parse_str(&user_id_str)
                .map_err(|_| ApiError::InternalError("Invalid cached user ID".to_string()))?;
            Ok(Some(user_id))
        }
        None => Ok(None),
    }
}

pub async fn delete_refresh_token(pool: &RedisPool, token: &str) -> ApiResult<()> {
    let mut conn = pool.get().await.map_err(|e| {
        tracing::error!("Failed to get Redis connection: {:?}", e);
        ApiError::InternalError("Cache connection error".to_string())
    })?;

    let key = format!("refresh_token:{}", token);
    let _: () = conn.del(&key).await?;

    tracing::debug!("Deleted refresh token");
    Ok(())
}

pub async fn cache_problem_set(
    pool: &RedisPool,
    key: &str,
    problems: &[MathProblem],
    ttl_seconds: u64,
) -> ApiResult<()> {
    let mut conn = pool.get().await.map_err(|e| {
        tracing::error!("Failed to get Redis connection: {:?}", e);
        ApiError::InternalError("Cache connection error".to_string())
    })?;

    let serialized = serde_json::to_string(problems)
        .map_err(|e| ApiError::InternalError(format!("Serialization error: {}", e)))?;

    let cache_key = format!("problems:{}", key);
    let _: () = conn.set_ex(&cache_key, serialized, ttl_seconds).await?;

    Ok(())
}

pub async fn get_cached_problem_set(
    pool: &RedisPool,
    key: &str,
) -> ApiResult<Option<Vec<MathProblem>>> {
    let mut conn = pool.get().await.map_err(|e| {
        tracing::error!("Failed to get Redis connection: {:?}", e);
        ApiError::InternalError("Cache connection error".to_string())
    })?;

    let cache_key = format!("problems:{}", key);
    let result: Option<String> = conn.get(&cache_key).await?;

    match result {
        Some(data) => {
            let problems: Vec<MathProblem> = serde_json::from_str(&data)
                .map_err(|e| ApiError::InternalError(format!("Deserialization error: {}", e)))?;
            Ok(Some(problems))
        }
        None => Ok(None),
    }
}

/// Increment a rate limit counter with sliding window
pub async fn increment_rate_limit(
    pool: &RedisPool,
    key: &str,
    window_seconds: u64,
) -> ApiResult<i64> {
    let mut conn = pool.get().await.map_err(|e| {
        tracing::error!("Failed to get Redis connection: {:?}", e);
        ApiError::InternalError("Cache connection error".to_string())
    })?;

    let count: i64 = conn.incr(key, 1i64).await?;
    if count == 1 {
        let _: () = conn.expire(key, window_seconds as i64).await?;
    }

    Ok(count)
}
