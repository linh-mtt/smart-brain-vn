use async_trait::async_trait;
use redis::AsyncCommands;
use uuid::Uuid;

use crate::error::{ApiError, ApiResult};
use crate::state::RedisPool;

#[async_trait]
pub trait TokenRepository: Send + Sync {
    async fn store_refresh_token(
        &self,
        user_id: Uuid,
        token: &str,
        ttl_seconds: u64,
    ) -> ApiResult<()>;
    async fn get_refresh_token(&self, token: &str) -> ApiResult<Option<Uuid>>;
    async fn delete_refresh_token(&self, token: &str) -> ApiResult<()>;
}

pub struct RedisTokenRepository {
    pool: RedisPool,
}

impl RedisTokenRepository {
    pub fn new(pool: RedisPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl TokenRepository for RedisTokenRepository {
    async fn store_refresh_token(
        &self,
        user_id: Uuid,
        token: &str,
        ttl_seconds: u64,
    ) -> ApiResult<()> {
        let mut conn = self.pool.get().await.map_err(|e| {
            tracing::error!("Failed to get Redis connection: {:?}", e);
            ApiError::InternalError("Cache connection error".to_string())
        })?;

        let key = format!("refresh_token:{}", token);
        let _: () = conn.set_ex(&key, user_id.to_string(), ttl_seconds).await?;

        tracing::debug!("Stored refresh token for user {}", user_id);
        Ok(())
    }

    async fn get_refresh_token(&self, token: &str) -> ApiResult<Option<Uuid>> {
        let mut conn = self.pool.get().await.map_err(|e| {
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

    async fn delete_refresh_token(&self, token: &str) -> ApiResult<()> {
        let mut conn = self.pool.get().await.map_err(|e| {
            tracing::error!("Failed to get Redis connection: {:?}", e);
            ApiError::InternalError("Cache connection error".to_string())
        })?;

        let key = format!("refresh_token:{}", token);
        let _: () = conn.del(&key).await?;

        tracing::debug!("Deleted refresh token");
        Ok(())
    }
}
