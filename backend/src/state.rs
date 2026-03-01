use std::sync::Arc;

use axum::extract::FromRef;
use bb8::Pool;
use bb8_redis::RedisConnectionManager;
use sqlx::postgres::PgPool;
use tokio::sync::broadcast;

use crate::config::Config;

use crate::handlers::auth::ConcreteAuthService;
use crate::handlers::practice::ConcreteAdaptiveEngine;
use crate::handlers::session::ConcreteSessionService;
use crate::handlers::leaderboard::ConcreteLeaderboardService;
pub type RedisPool = Pool<RedisConnectionManager>;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: RedisPool,
    pub config: Arc<Config>,
    pub ws_sender: broadcast::Sender<String>,
    pub auth_service: Arc<ConcreteAuthService>,
    pub adaptive_engine: Arc<ConcreteAdaptiveEngine>,
    pub session_service: Arc<ConcreteSessionService>,
    pub leaderboard_service: Arc<ConcreteLeaderboardService>,
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

impl FromRef<AppState> for Arc<ConcreteAdaptiveEngine> {
    fn from_ref(state: &AppState) -> Self {
        state.adaptive_engine.clone()
    }
}

impl FromRef<AppState> for Arc<ConcreteSessionService> {
    fn from_ref(state: &AppState) -> Self {
        state.session_service.clone()
    }
}

impl FromRef<AppState> for Arc<ConcreteLeaderboardService> {
    fn from_ref(state: &AppState) -> Self {
        state.leaderboard_service.clone()
    }
}
