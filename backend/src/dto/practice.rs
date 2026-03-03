use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;
use utoipa::ToSchema;
use utoipa::IntoParams;

// ─── Request DTOs ────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize, Validate, ToSchema, IntoParams)]
pub struct GetQuestionsRequest {
    pub topic: String,

    #[validate(range(min = 1, max = 20, message = "Count must be 1-20"))]
    pub count: Option<usize>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct PracticeSubmitRequest {
    pub question_id: Uuid,
    pub topic: String,
    pub difficulty_level: i32,
    pub question_text: String,
    pub correct_answer: f64,
    pub answer: f64,
    pub time_taken_ms: Option<i32>,
}

// ─── Response DTOs ───────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Clone, ToSchema)]
pub struct AdaptiveQuestionResponse {
    pub id: Uuid,
    pub question_text: String,
    pub correct_answer: f64,
    pub options: Vec<String>,
    pub explanation: String,
    pub topic: String,
    pub difficulty_level: i32,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct PracticeFeedbackResponse {
    pub is_correct: bool,
    pub correct_answer: f64,
    pub points_earned: i32,
    pub explanation: String,
    pub new_difficulty: i32,
    pub elo_rating: f64,
    pub weak_topics: Vec<String>,
    pub streak: i32,
}
