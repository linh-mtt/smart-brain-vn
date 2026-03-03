use axum::extract::State;
use axum::Json;
use sqlx::PgPool;

use crate::error::ApiResult;
use crate::state::RedisPool;

#[utoipa::path(get, path = "/api/v1/health", tag = "Health", responses((status = 200, description = "Health check status")))]
pub async fn health_check(
    State(pool): State<PgPool>,
    State(redis): State<RedisPool>,
) -> ApiResult<Json<serde_json::Value>> {
    // Check database connectivity
    let db_connected = sqlx::query_scalar::<_, i32>("SELECT 1")
        .fetch_one(&pool)
        .await
        .is_ok();

    // Check Redis connectivity
    let redis_connected = {
        match redis.get().await {
            Ok(mut conn) => {
                let result: Result<String, _> = redis::cmd("PING")
                    .query_async(&mut *conn)
                    .await;
                result.is_ok()
            }
            Err(_) => false,
        }
    };

    let status = if db_connected && redis_connected {
        "healthy"
    } else {
        "degraded"
    };

    Ok(Json(serde_json::json!({
        "status": status,
        "version": env!("CARGO_PKG_VERSION"),
        "db_connected": db_connected,
        "redis_connected": redis_connected,
    })))
}
