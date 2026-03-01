use redis::AsyncCommands;

use crate::error::{ApiError, ApiResult};
use crate::services::math_engine::MathProblem;
use crate::state::RedisPool;

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
