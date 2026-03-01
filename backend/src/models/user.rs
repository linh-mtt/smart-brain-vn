use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

// ─── User Role Enum ──────────────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "user_role", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum UserRole {
    Student,
    Parent,
    Admin,
}

impl std::fmt::Display for UserRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserRole::Student => write!(f, "student"),
            UserRole::Parent => write!(f, "parent"),
            UserRole::Admin => write!(f, "admin"),
        }
    }
}

impl UserRole {
    pub fn from_str_value(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "parent" => UserRole::Parent,
            "admin" => UserRole::Admin,
            _ => UserRole::Student,
        }
    }
}

// ─── User Model ──────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub password_hash: String,
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub grade_level: i32,
    pub age: Option<i32>,
    pub role: UserRole,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateProfileRequest {
    #[validate(length(max = 255, message = "Display name too long"))]
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    #[validate(range(min = 1, max = 6, message = "Grade level must be 1-6"))]
    pub grade_level: Option<i32>,
    #[validate(range(min = 4, max = 18, message = "Age must be 4-18"))]
    pub age: Option<i32>,
}


// ─── Exercise Models ─────────────────────────────────────────────────────────

#[derive(Debug, Deserialize, Validate)]
pub struct GenerateExerciseRequest {
    pub topic: String,
    pub difficulty: String,
    #[validate(range(min = 1, max = 20, message = "Count must be 1-20"))]
    pub count: usize,
}

#[derive(Debug, Deserialize)]
pub struct SubmitAnswerRequest {
    pub exercise_id: Uuid,
    pub answer: f64,
    pub time_taken_ms: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct ExerciseResponse {
    pub id: Uuid,
    pub question_text: String,
    pub options: Option<Vec<String>>,
    pub difficulty: String,
    pub topic: String,
}

#[derive(Debug, Serialize)]
pub struct AnswerFeedback {
    pub is_correct: bool,
    pub correct_answer: f64,
    pub points_earned: i32,
    pub explanation: String,
}

// ─── Progress Models ─────────────────────────────────────────────────────────

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct ProgressSummary {
    pub total_points: i64,
    pub current_streak: i32,
    pub longest_streak: i32,
    pub total_exercises: i64,
    pub accuracy_rate: f64,
    pub level: i32,
    pub xp_to_next_level: i64,
}

#[derive(Debug, Serialize)]
pub struct TopicProgressResponse {
    pub topic: String,
    pub mastery_score: f64,
    pub total_answered: i32,
    pub correct_count: i32,
    pub recent_scores: Vec<bool>,
}

// ─── Achievement Models ──────────────────────────────────────────────────────

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct AchievementResponse {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub emoji: String,
    pub reward_points: i32,
    pub is_unlocked: bool,
    pub unlocked_at: Option<DateTime<Utc>>,
}

// ─── Parent Models ───────────────────────────────────────────────────────────

#[derive(Debug, Serialize)]
pub struct ChildSummary {
    pub child_id: Uuid,
    pub username: String,
    pub display_name: Option<String>,
    pub grade_level: i32,
    pub total_points: i64,
    pub total_exercises: i64,
    pub current_streak: i32,
}

#[derive(Debug, Serialize)]
pub struct ChildProgress {
    pub child: ChildSummary,
    pub topic_mastery: Vec<TopicProgressResponse>,
    pub daily_goal: Option<DailyGoalResponse>,
    pub recent_activity: Vec<RecentExercise>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct DailyGoalResponse {
    pub daily_exercise_target: i32,
    pub daily_time_target_minutes: i32,
    pub active_topics: serde_json::Value,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateGoalsRequest {
    #[validate(range(min = 1, max = 100, message = "Target must be 1-100"))]
    pub daily_exercise_target: Option<i32>,
    #[validate(range(min = 5, max = 120, message = "Time target must be 5-120 minutes"))]
    pub daily_time_target_minutes: Option<i32>,
    pub active_topics: Option<Vec<String>>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct RecentExercise {
    pub id: Uuid,
    pub topic: String,
    pub difficulty: String,
    pub is_correct: bool,
    pub points_earned: i32,
    pub created_at: DateTime<Utc>,
}

// ─── Pagination ──────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct PaginationParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}

impl PaginationParams {
    pub fn offset(&self) -> i64 {
        let page = self.page.unwrap_or(1).max(1);
        let per_page = self.per_page();
        (page - 1) * per_page
    }

    pub fn per_page(&self) -> i64 {
        self.per_page.unwrap_or(20).clamp(1, 100)
    }
}

// ─── WebSocket Events ────────────────────────────────────────────────────────

#[derive(Debug, Serialize, Deserialize)]
#[allow(dead_code)]
pub struct WsEvent {
    pub event_type: String,
    pub user_id: Uuid,
    pub payload: serde_json::Value,
}
