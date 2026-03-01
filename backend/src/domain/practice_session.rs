use chrono::{DateTime, Utc};
use uuid::Uuid;

// ─── Session Status ──────────────────────────────────────────────────────────

/// Maps to the `session_status` PostgreSQL enum.
#[derive(Debug, Clone, PartialEq)]
pub enum SessionStatus {
    Active,
    Completed,
    Abandoned,
}

impl SessionStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            SessionStatus::Active => "active",
            SessionStatus::Completed => "completed",
            SessionStatus::Abandoned => "abandoned",
        }
    }

    pub fn from_str_value(s: &str) -> Option<Self> {
        match s {
            "active" => Some(SessionStatus::Active),
            "completed" => Some(SessionStatus::Completed),
            "abandoned" => Some(SessionStatus::Abandoned),
            _ => None,
        }
    }
}

// ─── Practice Session Domain Entity ──────────────────────────────────────────

/// Pure domain entity for a practice session lifecycle.
#[derive(Debug, Clone)]
pub struct PracticeSession {
    pub id: Uuid,
    pub user_id: Uuid,
    pub topic: String,
    pub status: SessionStatus,
    pub total_questions: i32,
    pub correct_count: i32,
    pub total_points: i32,
    pub total_time_ms: i64,
    pub max_combo: i32,
    pub current_combo: i32,
    pub difficulty_start: i32,
    pub difficulty_end: i32,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── Practice Result Domain Entity ───────────────────────────────────────────

/// Individual answer record within a practice session.
#[derive(Debug, Clone)]
pub struct PracticeResult {
    pub id: Uuid,
    pub session_id: Uuid,
    pub user_id: Uuid,
    pub question_id: Uuid,
    pub topic: String,
    pub difficulty_level: i32,
    pub question_text: String,
    pub correct_answer: f64,
    pub user_answer: f64,
    pub is_correct: bool,
    pub points_earned: i32,
    pub combo_multiplier: f64,
    pub combo_count: i32,
    pub time_taken_ms: Option<i32>,
    pub created_at: DateTime<Utc>,
}

// ─── Combo Algorithm (Pure Functions) ────────────────────────────────────────

/// Calculate the new combo count after an answer.
/// Combo increments on correct, resets to 0 on wrong.
pub fn calculate_combo(current_combo: i32, is_correct: bool) -> i32 {
    if is_correct {
        current_combo + 1
    } else {
        0
    }
}

/// Calculate combo multiplier from combo count.
/// Base multiplier is 1.0, increases by 0.1 per combo, capped at 3.0.
/// Thresholds: combo 3+ = 1.3x, combo 5+ = 1.5x, combo 10+ = 2.0x, combo 20+ = 3.0x (max).
pub fn calculate_combo_multiplier(combo_count: i32) -> f64 {
    (1.0 + (combo_count as f64 * 0.1)).min(3.0)
}

/// Calculate points for a single answer within a session,
/// incorporating combo multiplier.
/// Base points: easy(1-3)=5, medium(4-7)=10, hard(8-10)=20.
pub fn calculate_session_points(is_correct: bool, difficulty_level: i32, combo_count: i32) -> (i32, f64) {
    if !is_correct {
        return (0, 1.0);
    }

    let base_points = match difficulty_level {
        1..=3 => 5,
        4..=7 => 10,
        _ => 20,
    };

    let multiplier = calculate_combo_multiplier(combo_count);
    let points = (base_points as f64 * multiplier).round() as i32;
    (points, multiplier)
}

/// Calculate session accuracy as a percentage.
pub fn calculate_accuracy(total_questions: i32, correct_count: i32) -> f64 {
    if total_questions == 0 {
        return 0.0;
    }
    (correct_count as f64 / total_questions as f64) * 100.0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_combo_increments_on_correct() {
        assert_eq!(calculate_combo(0, true), 1);
        assert_eq!(calculate_combo(5, true), 6);
        assert_eq!(calculate_combo(99, true), 100);
    }

    #[test]
    fn test_combo_resets_on_wrong() {
        assert_eq!(calculate_combo(0, false), 0);
        assert_eq!(calculate_combo(10, false), 0);
        assert_eq!(calculate_combo(99, false), 0);
    }

    #[test]
    fn test_combo_multiplier_base() {
        let m = calculate_combo_multiplier(0);
        assert!((m - 1.0).abs() < 0.001, "No combo = 1.0x: {}", m);
    }

    #[test]
    fn test_combo_multiplier_scaling() {
        let m3 = calculate_combo_multiplier(3);
        assert!((m3 - 1.3).abs() < 0.001, "3-combo = 1.3x: {}", m3);

        let m10 = calculate_combo_multiplier(10);
        assert!((m10 - 2.0).abs() < 0.001, "10-combo = 2.0x: {}", m10);
    }

    #[test]
    fn test_combo_multiplier_caps_at_3() {
        let m = calculate_combo_multiplier(50);
        assert!((m - 3.0).abs() < 0.001, "Should cap at 3.0x: {}", m);
    }

    #[test]
    fn test_session_points_correct_easy() {
        let (points, mult) = calculate_session_points(true, 1, 0);
        assert_eq!(points, 5);
        assert!((mult - 1.0).abs() < 0.001);
    }

    #[test]
    fn test_session_points_correct_with_combo() {
        // difficulty 5 (medium=10 base), combo 5 (1.5x multiplier)
        let (points, mult) = calculate_session_points(true, 5, 5);
        assert_eq!(points, 15); // 10 * 1.5
        assert!((mult - 1.5).abs() < 0.001);
    }

    #[test]
    fn test_session_points_wrong() {
        let (points, mult) = calculate_session_points(false, 10, 20);
        assert_eq!(points, 0);
        assert!((mult - 1.0).abs() < 0.001);
    }

    #[test]
    fn test_session_points_hard_max_combo() {
        // difficulty 8 (hard=20 base), combo 30 (3.0x max)
        let (points, mult) = calculate_session_points(true, 8, 30);
        assert_eq!(points, 60); // 20 * 3.0
        assert!((mult - 3.0).abs() < 0.001);
    }

    #[test]
    fn test_accuracy_normal() {
        let acc = calculate_accuracy(10, 7);
        assert!((acc - 70.0).abs() < 0.001);
    }

    #[test]
    fn test_accuracy_zero_questions() {
        let acc = calculate_accuracy(0, 0);
        assert!((acc - 0.0).abs() < 0.001);
    }

    #[test]
    fn test_accuracy_perfect() {
        let acc = calculate_accuracy(20, 20);
        assert!((acc - 100.0).abs() < 0.001);
    }

    #[test]
    fn test_session_status_roundtrip() {
        for status in [SessionStatus::Active, SessionStatus::Completed, SessionStatus::Abandoned] {
            let s = status.as_str();
            let parsed = SessionStatus::from_str_value(s).unwrap();
            assert_eq!(parsed, status);
        }
    }

    #[test]
    fn test_session_status_invalid() {
        assert!(SessionStatus::from_str_value("invalid").is_none());
    }
}
