mod auth;
mod config;
mod db;
mod domain;
mod dto;
mod error;
mod handlers;
mod middleware;
mod models;
mod repository;
mod services;
mod state;
mod ws;

use std::net::SocketAddr;
use std::sync::Arc;

use bb8_redis::RedisConnectionManager;
use tokio::net::TcpListener;
use tokio::sync::broadcast;
use tower_http::compression::CompressionLayer;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing_subscriber::EnvFilter;

use crate::config::Config;
use crate::state::AppState;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .json()
        .init();

    tracing::info!("Starting SmartMath Backend v{}", env!("CARGO_PKG_VERSION"));

    // Load configuration
    let config = Config::from_env();
    tracing::info!("Environment: {}", config.environment);

    // Create PostgreSQL connection pool
    let db_pool = db::create_pool(&config)
        .await
        .expect("Failed to create database pool");

    // Run database migrations
    db::run_migrations(&db_pool)
        .await
        .expect("Failed to run database migrations");

    // Create Redis connection pool
    let redis_manager = RedisConnectionManager::new(config.redis_url.clone())
        .expect("Failed to create Redis connection manager");

    let redis_pool = bb8::Pool::builder()
        .max_size(20)
        .min_idle(Some(2))
        .build(redis_manager)
        .await
        .expect("Failed to create Redis pool");

    // Create auth service (Clean Architecture wiring)
    let user_repo = std::sync::Arc::new(
        crate::repository::user_repository::PgUserRepository::new(db_pool.clone()),
    );
    let token_repo = std::sync::Arc::new(
        crate::repository::token_repository::RedisTokenRepository::new(redis_pool.clone()),
    );
    let auth_service = std::sync::Arc::new(
        crate::services::auth_service::AuthService::new(
            user_repo,
            token_repo,
            std::sync::Arc::new(config.clone()),
        ),
    );
    tracing::info!("Redis connection pool created successfully");

    // Create adaptive engine (Clean Architecture wiring)
    let question_repo = std::sync::Arc::new(
        crate::repository::question_repository::PgQuestionRepository::new(db_pool.clone()),
    );
    let skill_repo = std::sync::Arc::new(
        crate::repository::skill_repository::PgSkillRepository::new(db_pool.clone()),
    );
    let adaptive_engine = std::sync::Arc::new(
        crate::services::adaptive_engine::AdaptiveEngine::new(
            question_repo,
            skill_repo,
            std::sync::Arc::new(config.clone()),
        ),
    );

    // Create session service (Clean Architecture wiring)
    let session_repo = std::sync::Arc::new(
        crate::repository::session_repository::PgSessionRepository::new(db_pool.clone()),
    );
    let session_service = std::sync::Arc::new(
        crate::services::session_service::SessionService::new(
            session_repo,
            adaptive_engine.clone(),
            std::sync::Arc::new(config.clone()),
        ),
    );

    // Create leaderboard service (Clean Architecture wiring)
    let leaderboard_repo = std::sync::Arc::new(
        crate::repository::leaderboard_repository::PgLeaderboardRepository::new(db_pool.clone()),
    );
    let leaderboard_service = std::sync::Arc::new(
        crate::services::leaderboard_service::LeaderboardService::new(
            leaderboard_repo,
            redis_pool.clone(),
            std::sync::Arc::new(config.clone()),
        ),
    );

    // Create broadcast channel for WebSocket events
    let (ws_sender, _) = broadcast::channel::<String>(1024);

    // Build application state
    let state = AppState {
        db: db_pool,
        redis: redis_pool,
        config: Arc::new(config.clone()),
        ws_sender,
        auth_service,
        adaptive_engine,
        session_service,
        leaderboard_service,
    };

    // Build middleware stack
    let cors = CorsLayer::permissive();
    let trace = TraceLayer::new_for_http();
    let compression = CompressionLayer::new();

    // Build router
    let app = axum::Router::new()
        .nest("/api/v1", handlers::api_router(state.clone()))
        .layer(compression)
        .layer(cors)
        .layer(trace)
        .with_state(state);

    // Bind and serve
    let addr = SocketAddr::new(
        config
            .server_host
            .parse()
            .expect("Invalid server host address"),
        config.server_port,
    );

    tracing::info!("Listening on {}", addr);

    let listener = TcpListener::bind(addr)
        .await
        .expect("Failed to bind TCP listener");

    axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())
        .with_graceful_shutdown(shutdown_signal())
        .await
        .expect("Server error");
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("Failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {
            tracing::info!("Received Ctrl+C, initiating graceful shutdown");
        },
        _ = terminate => {
            tracing::info!("Received SIGTERM, initiating graceful shutdown");
        },
    }
}
