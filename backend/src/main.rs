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
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use crate::config::Config;
use crate::state::AppState;

// ─── OpenAPI Documentation ────────────────────────────────────────────────────

struct JwtSecurityAddon;

impl utoipa::Modify for JwtSecurityAddon {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        if let Some(components) = openapi.components.as_mut() {
            components.add_security_scheme(
                "bearer_jwt",
                utoipa::openapi::security::SecurityScheme::Http(
                    utoipa::openapi::security::HttpBuilder::new()
                        .scheme(utoipa::openapi::security::HttpAuthScheme::Bearer)
                        .bearer_format("JWT")
                        .build(),
                ),
            );
        }
    }
}

#[derive(OpenApi)]
#[openapi(
    info(
        title = "SmartMath Kids API",
        version = "1.0.0",
        description = "Interactive math learning platform for children — REST API documentation",
        contact(name = "SmartMath Team"),
        license(name = "MIT")
    ),
    modifiers(&JwtSecurityAddon),
    paths(
        handlers::auth::register,
        handlers::auth::login,
        handlers::auth::google_login,
        handlers::auth::refresh,
        handlers::auth::logout,
        handlers::user::get_me,
        handlers::user::update_me,
        handlers::exercise::generate,
        handlers::exercise::submit,
        handlers::exercise::history,
        handlers::progress::summary,
        handlers::progress::topic_progress,
        handlers::achievement::list_achievements,
        handlers::leaderboard::get_leaderboard,
        handlers::leaderboard::get_my_rank,
        handlers::practice::get_questions,
        handlers::practice::submit_practice,
        handlers::session::start_session,
        handlers::session::submit_answer,
        handlers::session::get_result,
        handlers::parent::list_children,
        handlers::parent::child_progress,
        handlers::parent::update_goals,
        handlers::xp::get_xp_profile,
        handlers::xp::get_themes,
        handlers::xp::unlock_theme,
        handlers::xp::activate_theme,
        handlers::health::health_check,
    ),
    components(schemas(
        dto::auth::CreateUserRequest,
        dto::auth::LoginRequest,
        dto::auth::GoogleLoginRequest,
        dto::auth::RefreshTokenRequest,
        dto::auth::UserResponse,
        dto::auth::AuthResponse,
        dto::auth::TokenClaims,
        dto::xp::XpProfileResponse,
        dto::xp::XpAwardResponse,
        dto::xp::UnlockedAchievementDto,
        dto::xp::ThemeResponse,
        dto::xp::ThemeListResponse,
        dto::xp::ActivateThemeRequest,
        dto::leaderboard::LeaderboardQueryParams,
        dto::leaderboard::LeaderboardResponse,
        dto::leaderboard::LeaderboardEntryDto,
        dto::leaderboard::MyRankDto,
        dto::session::StartSessionRequest,
        dto::session::SessionSubmitRequest,
        dto::session::StartSessionResponse,
        dto::session::SessionSubmitResponse,
        dto::session::SessionProgress,
        dto::session::SessionResultResponse,
        dto::session::ResultDetail,
        dto::practice::GetQuestionsRequest,
        dto::practice::PracticeSubmitRequest,
        dto::practice::AdaptiveQuestionResponse,
        dto::practice::PracticeFeedbackResponse,
        models::user::UserRole,
        models::user::UpdateProfileRequest,
        models::user::GenerateExerciseRequest,
        models::user::SubmitAnswerRequest,
        models::user::ExerciseResponse,
        models::user::AnswerFeedback,
        models::user::ProgressSummary,
        models::user::TopicProgressResponse,
        models::user::AchievementResponse,
        models::user::ChildSummary,
        models::user::ChildProgress,
        models::user::DailyGoalResponse,
        models::user::UpdateGoalsRequest,
        models::user::RecentExercise,
        models::user::PaginationParams,
        error::ErrorResponse,
    )),
    tags(
        (name = "Health", description = "Service health checks"),
        (name = "Authentication", description = "User registration, login, token refresh, logout"),
        (name = "Users", description = "User profile management"),
        (name = "Exercises", description = "Math exercise generation and submission"),
        (name = "Progress", description = "Learning progress and topic mastery"),
        (name = "Achievements", description = "Achievement tracking"),
        (name = "Leaderboard", description = "Competition rankings"),
        (name = "Practice", description = "Adaptive practice engine"),
        (name = "Practice Sessions", description = "Session-based practice with combos"),
        (name = "Parent", description = "Parental oversight and goal setting"),
        (name = "XP & Gamification", description = "XP, levels, themes, and rewards"),
    )
)]
struct ApiDoc;

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

    // Create XP service (pool-based, no repository abstraction needed)
    let xp_service = std::sync::Arc::new(
        crate::services::xp_service::XpService::new(db_pool.clone()),
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
        xp_service,
    };

    // Build middleware stack
    let cors = CorsLayer::permissive();
    let trace = TraceLayer::new_for_http();
    let compression = CompressionLayer::new();

    // Build router
    let app = axum::Router::new()
        .nest("/api/v1", handlers::api_router(state.clone()))
        .merge(
            SwaggerUi::new("/docs/backend-apis")
                .url("/api-docs/openapi.json", ApiDoc::openapi())
        )
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
