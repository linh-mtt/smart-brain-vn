use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::services::math_engine::Difficulty;

// ─── Points Calculation ──────────────────────────────────────────────────────

pub fn calculate_points(is_correct: bool, difficulty: &Difficulty, streak: i32) -> i32 {
    if !is_correct {
        return 0;
    }

    let base_points = match difficulty {
        Difficulty::Easy => 5,
        Difficulty::Medium => 10,
        Difficulty::Hard => 20,
    };

    let multiplier = (1.0 + (streak as f64 * 0.1)).min(3.0);
    (base_points as f64 * multiplier).round() as i32
}

// ─── Level Calculation ───────────────────────────────────────────────────────

/// Returns (level, current_xp_in_level, xp_needed_for_next_level)
pub fn calculate_level(total_xp: i64) -> (i32, i64, i64) {
    let mut level = 1;
    let mut remaining_xp = total_xp;

    loop {
        let xp_for_this_level = (level as i64) * 100;
        if remaining_xp < xp_for_this_level {
            return (level, remaining_xp, xp_for_this_level);
        }
        remaining_xp -= xp_for_this_level;
        level += 1;
    }
}

// ─── Achievement Checking ────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserStats {
    pub total_answered: i64,
    pub total_correct: i64,
    pub current_streak: i32,
    pub longest_streak: i32,
    pub total_points: i64,
    pub day_streak: i32,
    pub level: i32,
    pub addition_total: i64,
    pub addition_correct: i64,
    pub subtraction_total: i64,
    pub subtraction_correct: i64,
    pub multiplication_total: i64,
    pub multiplication_correct: i64,
    pub division_total: i64,
    pub division_correct: i64,
    pub fastest_five_ms: Option<i64>,
    pub perfect_session: bool,
    pub perfect_session_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AchievementUnlock {
    pub achievement_name: String,
    pub achievement_id: Option<Uuid>,
}

pub fn check_achievements(user_stats: &UserStats) -> Vec<AchievementUnlock> {
    let mut unlocks = Vec::new();

    // first_step: Answer first question
    if user_stats.total_answered >= 1 {
        unlocks.push(AchievementUnlock {
            achievement_name: "first_step".to_string(),
            achievement_id: None,
        });
    }

    // ten_streak: 10 correct in a row
    if user_stats.current_streak >= 10 || user_stats.longest_streak >= 10 {
        unlocks.push(AchievementUnlock {
            achievement_name: "ten_streak".to_string(),
            achievement_id: None,
        });
    }

    // hundred_correct: 100 total correct
    if user_stats.total_correct >= 100 {
        unlocks.push(AchievementUnlock {
            achievement_name: "hundred_correct".to_string(),
            achievement_id: None,
        });
    }

    // addition_master: 90% accuracy in addition (min 50 questions)
    if user_stats.addition_total >= 50 {
        let accuracy =
            (user_stats.addition_correct as f64 / user_stats.addition_total as f64) * 100.0;
        if accuracy >= 90.0 {
            unlocks.push(AchievementUnlock {
                achievement_name: "addition_master".to_string(),
                achievement_id: None,
            });
        }
    }

    // subtraction_master
    if user_stats.subtraction_total >= 50 {
        let accuracy =
            (user_stats.subtraction_correct as f64 / user_stats.subtraction_total as f64) * 100.0;
        if accuracy >= 90.0 {
            unlocks.push(AchievementUnlock {
                achievement_name: "subtraction_master".to_string(),
                achievement_id: None,
            });
        }
    }

    // multiplication_master
    if user_stats.multiplication_total >= 50 {
        let accuracy = (user_stats.multiplication_correct as f64
            / user_stats.multiplication_total as f64)
            * 100.0;
        if accuracy >= 90.0 {
            unlocks.push(AchievementUnlock {
                achievement_name: "multiplication_master".to_string(),
                achievement_id: None,
            });
        }
    }

    // division_master
    if user_stats.division_total >= 50 {
        let accuracy =
            (user_stats.division_correct as f64 / user_stats.division_total as f64) * 100.0;
        if accuracy >= 90.0 {
            unlocks.push(AchievementUnlock {
                achievement_name: "division_master".to_string(),
                achievement_id: None,
            });
        }
    }

    // speed_demon: Answer 5 in under 30 seconds total
    if let Some(fastest_five) = user_stats.fastest_five_ms {
        if fastest_five <= 30000 {
            unlocks.push(AchievementUnlock {
                achievement_name: "speed_demon".to_string(),
                achievement_id: None,
            });
        }
    }

    // perfect_day: 100% accuracy in a session (min 10 questions)
    if user_stats.perfect_session && user_stats.perfect_session_count >= 10 {
        unlocks.push(AchievementUnlock {
            achievement_name: "perfect_day".to_string(),
            achievement_id: None,
        });
    }

    // week_warrior: 7-day streak
    if user_stats.day_streak >= 7 {
        unlocks.push(AchievementUnlock {
            achievement_name: "week_warrior".to_string(),
            achievement_id: None,
        });
    }

    // month_champion: 30-day streak
    if user_stats.day_streak >= 30 {
        unlocks.push(AchievementUnlock {
            achievement_name: "month_champion".to_string(),
            achievement_id: None,
        });
    }

    // level_5
    if user_stats.level >= 5 {
        unlocks.push(AchievementUnlock {
            achievement_name: "level_5".to_string(),
            achievement_id: None,
        });
    }

    // level_10
    if user_stats.level >= 10 {
        unlocks.push(AchievementUnlock {
            achievement_name: "level_10".to_string(),
            achievement_id: None,
        });
    }

    // level_20
    if user_stats.level >= 20 {
        unlocks.push(AchievementUnlock {
            achievement_name: "level_20".to_string(),
            achievement_id: None,
        });
    }

    // thousand_points: Earn 1000 total points
    if user_stats.total_points >= 1000 {
        unlocks.push(AchievementUnlock {
            achievement_name: "thousand_points".to_string(),
            achievement_id: None,
        });
    }

    unlocks
}
