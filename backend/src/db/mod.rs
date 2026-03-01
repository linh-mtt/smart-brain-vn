use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;

use crate::config::Config;
use crate::error::ApiResult;

pub async fn create_pool(config: &Config) -> ApiResult<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(20)
        .min_connections(2)
        .acquire_timeout(Duration::from_secs(5))
        .idle_timeout(Duration::from_secs(600))
        .max_lifetime(Duration::from_secs(1800))
        .connect(&config.database_url)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create database pool: {:?}", e);
            crate::error::ApiError::InternalError(format!("Database connection failed: {}", e))
        })?;

    tracing::info!("Database connection pool created successfully");
    Ok(pool)
}

pub async fn run_migrations(pool: &PgPool) -> ApiResult<()> {
    sqlx::migrate!("./migrations")
        .run(pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to run database migrations: {:?}", e);
            crate::error::ApiError::InternalError(format!("Migration failed: {}", e))
        })?;

    tracing::info!("Database migrations applied successfully");
    Ok(())
}
