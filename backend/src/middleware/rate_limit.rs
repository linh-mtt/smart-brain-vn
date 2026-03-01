use axum::body::Body;
use axum::extract::{ConnectInfo, State};
use axum::http::{Request, StatusCode};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use serde_json::json;
use std::net::SocketAddr;

use crate::services::cache::increment_rate_limit;
use crate::state::RedisPool;

/// Rate limiting middleware for general API routes.
/// 100 requests per minute per IP.
pub async fn rate_limit_general(
    State(pool): State<RedisPool>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    request: Request<Body>,
    next: Next,
) -> Response {
    let key = format!("rate_limit:general:{}", addr.ip());
    match increment_rate_limit(&pool, &key, 60).await {
        Ok(count) if count > 100 => {
            return rate_limit_exceeded_response(60);
        }
        Err(e) => {
            tracing::warn!("Rate limit check failed, allowing request: {:?}", e);
        }
        _ => {}
    }

    next.run(request).await
}

/// Rate limiting middleware for auth routes (login/register).
/// 5 requests per minute per IP.
pub async fn rate_limit_auth(
    State(pool): State<RedisPool>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    request: Request<Body>,
    next: Next,
) -> Response {
    let key = format!("rate_limit:auth:{}", addr.ip());
    match increment_rate_limit(&pool, &key, 60).await {
        Ok(count) if count > 5 => {
            return rate_limit_exceeded_response(60);
        }
        Err(e) => {
            tracing::warn!("Rate limit check failed, allowing request: {:?}", e);
        }
        _ => {}
    }

    next.run(request).await
}

fn rate_limit_exceeded_response(retry_after: u64) -> Response {
    let body = json!({
        "error": "rate_limit_exceeded",
        "message": "Too many requests. Please try again later.",
    });

    (
        StatusCode::TOO_MANY_REQUESTS,
        [("Retry-After", retry_after.to_string())],
        axum::Json(body),
    )
        .into_response()
}
