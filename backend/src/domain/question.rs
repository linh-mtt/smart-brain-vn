use chrono::{DateTime, Utc};
use uuid::Uuid;

/// Pure domain entity for question bank entries.
/// No sqlx, no serde — business logic only.
#[derive(Debug, Clone)]
pub struct DomainQuestion {
    pub id: Uuid,
    pub topic: String,
    pub difficulty_level: i32,
    pub question_template: String,
    pub operand_min: i32,
    pub operand_max: i32,
    pub explanation_template: String,
    pub grade_min: i32,
    pub grade_max: i32,
    pub active: bool,
    pub created_at: DateTime<Utc>,
}
