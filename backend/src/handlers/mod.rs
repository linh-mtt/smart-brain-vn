pub mod achievement;
pub mod auth;
pub mod exercise;
pub mod health;
pub mod leaderboard;
pub mod parent;
pub mod progress;
pub mod user;
pub mod practice;
pub mod session;

use axum::middleware as axum_mw;
use axum::routing::{get, post, put};
use axum::Router;

use crate::middleware::rate_limit::{rate_limit_auth, rate_limit_general};
use crate::state::AppState;

pub fn api_router(state: AppState) -> Router<AppState> {
    // Auth routes with stricter rate limiting (5 req/min)
    let auth_routes = Router::new()
        .route("/auth/register", post(auth::register))
        .route("/auth/login", post(auth::login))
        .route("/auth/refresh", post(auth::refresh))
        .route("/auth/logout", post(auth::logout))
        .layer(axum_mw::from_fn_with_state(state.clone(), rate_limit_auth));

    // All other routes with general rate limiting (100 req/min)
    let general_routes = Router::new()
        // User routes (protected)
        .route("/users/me", get(user::get_me).put(user::update_me))
        // Health check
        .route("/health", get(health::health_check))
        // WebSocket
        .route("/ws", get(crate::ws::ws_handler))
        // Exercise routes (protected)
        .route("/exercises/generate", post(exercise::generate))
        .route("/exercises/submit", post(exercise::submit))
        .route("/exercises/history", get(exercise::history))
        // Progress routes (protected)
        .route("/progress/summary", get(progress::summary))
        .route("/progress/topic/{topic}", get(progress::topic_progress))
        // Achievement routes (protected)
        .route("/achievements", get(achievement::list_achievements))
        // Leaderboard routes (protected)
        .route("/leaderboard", get(leaderboard::get_leaderboard))
        // Practice routes (adaptive engine, protected)
        .route("/practice/questions", get(practice::get_questions))
        .route("/practice/submit", post(practice::submit_practice))
        // Practice session routes (session-based practice, protected)
        .route("/practice/start", post(session::start_session))
        .route("/practice/answer", post(session::submit_answer))
        .route("/practice/result/{id}", get(session::get_result))
        // Parent routes (protected)
        .route("/parent/children", get(parent::list_children))
        .route(
            "/parent/child/{child_id}/progress",
            get(parent::child_progress),
        )
        .route(
            "/parent/child/{child_id}/goals",
            put(parent::update_goals),
        )
        .layer(axum_mw::from_fn_with_state(state, rate_limit_general));

    auth_routes.merge(general_routes)
}
