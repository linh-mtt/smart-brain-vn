use std::sync::Arc;

use axum::extract::FromRef;
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use sqlx::postgres::PgPool;
use tokio::sync::broadcast;

use crate::config::Config;

use crate::handlers::auth::ConcreteAuthService;
pub type RedisPool = Pool<RedisConnectionManager>;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: RedisPool,
    pub config: Arc<Config>,
    pub ws_sender: broadcast::Sender<String>,
    pub auth_service: Arc<ConcreteAuthService>,
}

impl FromRef<AppState> for PgPool {
    fn from_ref(state: &AppState) -> Self {
        state.db.clone()
    }
}

impl FromRef<AppState> for RedisPool {
    fn from_ref(state: &AppState) -> Self {
        state.redis.clone()
    }
}

impl FromRef<AppState> for Arc<Config> {
    fn from_ref(state: &AppState) -> Self {
        state.config.clone()
    }
}

impl FromRef<AppState> for broadcast::Sender<String> {
    fn from_ref(state: &AppState) -> Self {
        state.ws_sender.clone()
    }
}

impl FromRef<AppState> for Arc<ConcreteAuthService> {
    fn from_ref(state: &AppState) -> Self {
        state.auth_service.clone()
    }
}
