use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;
use utoipa::ToSchema;

// ─── Request DTOs ────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct StartSessionRequest {
    pub topic: String,

    #[validate(range(min = 1, max = 20, message = "Question count must be 1-20"))]
    pub question_count: Option<usize>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct SessionSubmitRequest {
    pub session_id: Uuid,
    pub question_id: Uuid,
    pub topic: String,

    #[validate(range(min = 1, max = 10, message = "Difficulty must be 1-10"))]
    pub difficulty_level: i32,

    pub question_text: String,
    pub correct_answer: f64,
    pub answer: f64,

    #[validate(range(min = 0, max = 300000, message = "Time must be 0-300000ms"))]
    pub time_taken_ms: Option<i32>,
}

// ─── Response DTOs ───────────────────────────────────────────────────────────

#[derive(Debug, Serialize, ToSchema)]
pub struct StartSessionResponse {
    pub session_id: Uuid,
    pub topic: String,
    pub difficulty_start: i32,
    pub questions: Vec<super::practice::AdaptiveQuestionResponse>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct SessionSubmitResponse {
    pub is_correct: bool,
    pub correct_answer: f64,
    pub points_earned: i32,
    pub combo_count: i32,
    pub combo_multiplier: f64,
    pub max_combo: i32,
    pub new_difficulty: i32,
    pub elo_rating: f64,
    pub streak: i32,
    pub weak_topics: Vec<String>,
    pub session_progress: SessionProgress,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct SessionProgress {
    pub total_questions: i32,
    pub correct_count: i32,
    pub total_points: i32,
    pub total_time_ms: i64,
    pub accuracy: f64,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct SessionResultResponse {
    pub session_id: Uuid,
    pub user_id: Uuid,
    pub topic: String,
    pub status: String,
    pub total_questions: i32,
    pub correct_count: i32,
    pub accuracy: f64,
    pub total_points: i32,
    pub total_time_ms: i64,
    pub max_combo: i32,
    pub difficulty_start: i32,
    pub difficulty_end: i32,
    pub started_at: chrono::DateTime<chrono::Utc>,
    pub completed_at: Option<chrono::DateTime<chrono::Utc>>,
    pub results: Vec<ResultDetail>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ResultDetail {
    pub id: Uuid,
    pub question_text: String,
    pub correct_answer: f64,
    pub user_answer: f64,
    pub is_correct: bool,
    pub points_earned: i32,
    pub combo_count: i32,
    pub combo_multiplier: f64,
    pub time_taken_ms: Option<i32>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}
