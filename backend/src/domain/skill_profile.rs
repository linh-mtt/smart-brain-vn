use chrono::{DateTime, Utc};
use uuid::Uuid;

/// Pure domain entity for per-user/per-topic adaptive skill state.
#[derive(Debug, Clone)]
pub struct SkillProfile {
    pub id: Uuid,
    pub user_id: Uuid,
    pub topic: String,
    pub current_difficulty: i32,
    pub elo_rating: f64,
    pub recent_accuracy: f64,
    pub last_n_results: Vec<bool>,
    pub consecutive_correct: i32,
    pub consecutive_wrong: i32,
    pub next_review_at: DateTime<Utc>,
    pub review_interval_days: f64,
    pub ease_factor: f64,
    pub total_attempts: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── Adaptive Algorithm (Pure Functions) ─────────────────────────────────────

/// Calculate new difficulty level based on performance.
/// Uses sliding window of last N results + consecutive streaks.
/// Returns new difficulty level clamped to 1-10.
pub fn calculate_new_difficulty(profile: &SkillProfile, is_correct: bool) -> i32 {
    let consecutive_correct = if is_correct {
        profile.consecutive_correct + 1
    } else {
        0
    };
    let consecutive_wrong = if !is_correct {
        profile.consecutive_wrong + 1
    } else {
        0
    };

    let current = profile.current_difficulty;

    // Level up: 3 consecutive correct answers
    if consecutive_correct >= 3 {
        return (current + 1).min(10);
    }

    // Level down: 2 consecutive wrong answers
    if consecutive_wrong >= 2 {
        return (current - 1).max(1);
    }

    // Check recent accuracy (last 5 from the sliding window)
    let recent = &profile.last_n_results;
    if recent.len() >= 5 {
        let last_5_correct = recent.iter().rev().take(5).filter(|&&r| r).count();
        let accuracy = last_5_correct as f64 / 5.0;

        if accuracy >= 0.9 {
            return (current + 1).min(10);
        }
        if accuracy <= 0.3 {
            return (current - 1).max(1);
        }
    }

    current // no change
}

/// Update Elo rating after an answer.
/// K-factor = 32 (standard for educational context).
/// Expected score based on difficulty difference.
pub fn update_elo(current_elo: f64, difficulty_level: i32, is_correct: bool) -> f64 {
    let k_factor = 32.0;
    // Maps difficulty 1-10 to Elo range 880-1600
    let difficulty_elo = 800.0 + (difficulty_level as f64 * 80.0);
    let expected = 1.0 / (1.0 + 10.0_f64.powf((difficulty_elo - current_elo) / 400.0));
    let actual = if is_correct { 1.0 } else { 0.0 };
    current_elo + k_factor * (actual - expected)
}

/// SM-2 spaced repetition update.
/// Returns (new_interval_days, new_ease_factor).
pub fn update_spaced_repetition(
    current_interval: f64,
    current_ease: f64,
    quality: i32, // 0-5, where 0=complete fail, 5=perfect
) -> (f64, f64) {
    let q = quality as f64;
    let new_ease = (current_ease + 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)).max(1.3);

    let new_interval = if quality < 3 {
        1.0 // reset on failure
    } else if current_interval < 1.0 {
        1.0
    } else if current_interval < 6.0 {
        6.0
    } else {
        current_interval * new_ease
    };

    (new_interval, new_ease)
}

/// Map answer correctness + speed to SM-2 quality score (0-5).
pub fn answer_to_quality(is_correct: bool, time_taken_ms: Option<i32>) -> i32 {
    if !is_correct {
        return 1;
    }
    match time_taken_ms {
        Some(ms) if ms < 5000 => 5,  // correct + fast
        Some(ms) if ms < 15000 => 4, // correct + moderate
        Some(_) => 3,                 // correct + slow
        None => 4,                    // correct, unknown speed
    }
}

/// Detect weak skills from a set of skill profiles.
/// A topic is "weak" if: accuracy < 50% AND total_attempts >= 5.
pub fn detect_weak_topics(profiles: &[SkillProfile]) -> Vec<String> {
    profiles
        .iter()
        .filter(|p| p.total_attempts >= 5 && p.recent_accuracy < 50.0)
        .map(|p| p.topic.clone())
        .collect()
}

/// Select which topics need review (spaced repetition due).
#[allow(dead_code)]
pub fn topics_due_for_review(profiles: &[SkillProfile], now: DateTime<Utc>) -> Vec<String> {
    profiles
        .iter()
        .filter(|p| p.next_review_at <= now)
        .map(|p| p.topic.clone())
        .collect()
}

/// Update the sliding window of last N results (keep last 10).
pub fn update_last_n_results(current: &[bool], new_result: bool) -> Vec<bool> {
    let mut results = current.to_vec();
    results.push(new_result);
    if results.len() > 10 {
        results.drain(..results.len() - 10);
    }
    results
}

/// Calculate recent accuracy from last_n_results as a percentage.
pub fn calculate_recent_accuracy(results: &[bool]) -> f64 {
    if results.is_empty() {
        return 0.0;
    }
    let correct = results.iter().filter(|&&r| r).count() as f64;
    (correct / results.len() as f64) * 100.0
}
