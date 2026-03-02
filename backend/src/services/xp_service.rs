use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use crate::dto::xp::{
    ThemeListResponse, ThemeResponse, UnlockedAchievementDto, XpAwardResponse, XpProfileResponse,
};
use crate::error::{ApiError, ApiResult};
use crate::models::theme::ThemeWithStatus;
use crate::services::gamification;

// ─── XP Service ─────────────────────────────────────────────────────────────

pub struct XpService {
    db: PgPool,
}

impl XpService {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    /// Get the full XP profile for a user.
    pub async fn get_profile(&self, user_id: Uuid) -> ApiResult<XpProfileResponse> {
        let row = sqlx::query_as::<_, (i64, i32)>(
            "SELECT total_xp, current_level FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?
        .ok_or_else(|| ApiError::NotFound("User not found".to_string()))?;

        let total_xp = row.0;
        let current_level = row.1;
        let (_, xp_in_level, xp_for_next) = gamification::calculate_level(total_xp);

        let progress_percent = if xp_for_next > 0 {
            (xp_in_level as f64 / xp_for_next as f64) * 100.0
        } else {
            0.0
        };

        // Get unlocked achievements
        let achievements = sqlx::query_as::<_, (Uuid, String, String, String, i32, chrono::DateTime<Utc>)>(
            r#"
            SELECT a.id, a.name, a.description, a.emoji, a.reward_points, ua.unlocked_at
            FROM user_achievements ua
            JOIN achievements a ON a.id = ua.achievement_id
            WHERE ua.user_id = $1
            ORDER BY ua.unlocked_at DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.db)
        .await?;

        let unlocked_achievements = achievements
            .into_iter()
            .map(|(id, name, description, emoji, reward_points, unlocked_at)| {
                UnlockedAchievementDto {
                    id,
                    name,
                    description,
                    emoji,
                    reward_points,
                    unlocked_at,
                }
            })
            .collect();

        // Get active theme
        let active_theme = self.get_active_theme(user_id).await?;

        Ok(XpProfileResponse {
            user_id,
            total_xp,
            current_level,
            xp_in_current_level: xp_in_level,
            xp_for_next_level: xp_for_next,
            xp_progress_percent: progress_percent,
            unlocked_achievements,
            active_theme,
        })
    }

    /// Award XP to a user, handling level-ups and achievement checks.
    pub async fn award_xp(
        &self,
        user_id: Uuid,
        xp_amount: i32,
    ) -> ApiResult<XpAwardResponse> {
        if xp_amount <= 0 {
            return Ok(XpAwardResponse {
                xp_awarded: 0,
                total_xp: 0,
                previous_level: 1,
                current_level: 1,
                leveled_up: false,
                xp_in_current_level: 0,
                xp_for_next_level: 100,
                newly_unlocked_achievements: Vec::new(),
            });
        }

        // Atomically update XP and get old + new values
        let row = sqlx::query_as::<_, (i64, i32)>(
            r#"
            UPDATE users
            SET total_xp = total_xp + $2,
                current_level = (
                    SELECT level FROM (
                        WITH RECURSIVE levels AS (
                            SELECT 1 AS lvl, $2::bigint + total_xp AS remaining_xp, 100::bigint AS threshold
                            FROM users WHERE id = $1
                            UNION ALL
                            SELECT lvl + 1, remaining_xp - threshold, (lvl + 1)::bigint * 100
                            FROM levels WHERE remaining_xp >= threshold
                        )
                        SELECT lvl AS level FROM levels ORDER BY lvl DESC LIMIT 1
                    ) sub
                )
            WHERE id = $1
            RETURNING total_xp, current_level
            "#,
        )
        .bind(user_id)
        .bind(xp_amount as i64)
        .fetch_optional(&self.db)
        .await?
        .ok_or_else(|| ApiError::NotFound("User not found".to_string()))?;

        let new_total_xp = row.0;
        let new_level = row.1;
        let old_total_xp = new_total_xp - xp_amount as i64;
        let (old_level, _, _) = gamification::calculate_level(old_total_xp);
        let (_, xp_in_level, xp_for_next) = gamification::calculate_level(new_total_xp);

        let leveled_up = new_level > old_level;

        // Check and unlock achievements
        let newly_unlocked = self.check_and_unlock_achievements(user_id).await?;

        Ok(XpAwardResponse {
            xp_awarded: xp_amount,
            total_xp: new_total_xp,
            previous_level: old_level,
            current_level: new_level,
            leveled_up,
            xp_in_current_level: xp_in_level,
            xp_for_next_level: xp_for_next,
            newly_unlocked_achievements: newly_unlocked,
        })
    }

    /// Check all achievement conditions and unlock any newly earned ones.
    pub async fn check_and_unlock_achievements(
        &self,
        user_id: Uuid,
    ) -> ApiResult<Vec<UnlockedAchievementDto>> {
        // Build UserStats from the database
        let user_stats = self.build_user_stats(user_id).await?;

        // Get potential unlocks from gamification module
        let potential = gamification::check_achievements(&user_stats);

        if potential.is_empty() {
            return Ok(Vec::new());
        }

        // Get already-unlocked achievement names
        let already_unlocked: Vec<String> = sqlx::query_scalar(
            r#"
            SELECT a.name
            FROM user_achievements ua
            JOIN achievements a ON a.id = ua.achievement_id
            WHERE ua.user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.db)
        .await?;

        let mut newly_unlocked = Vec::new();

        for unlock in potential {
            if already_unlocked.contains(&unlock.achievement_name) {
                continue;
            }

            // Look up the achievement by name
            let achievement = sqlx::query_as::<_, (Uuid, String, String, String, i32)>(
                "SELECT id, name, description, emoji, reward_points FROM achievements WHERE name = $1",
            )
            .bind(&unlock.achievement_name)
            .fetch_optional(&self.db)
            .await?;

            if let Some((ach_id, name, description, emoji, reward_points)) = achievement {
                // Insert into user_achievements (ignore conflicts = already unlocked)
                let inserted = sqlx::query_scalar::<_, chrono::DateTime<Utc>>(
                    r#"
                    INSERT INTO user_achievements (user_id, achievement_id)
                    VALUES ($1, $2)
                    ON CONFLICT (user_id, achievement_id) DO NOTHING
                    RETURNING unlocked_at
                    "#,
                )
                .bind(user_id)
                .bind(ach_id)
                .fetch_optional(&self.db)
                .await?;

                if let Some(unlocked_at) = inserted {
                    newly_unlocked.push(UnlockedAchievementDto {
                        id: ach_id,
                        name,
                        description,
                        emoji,
                        reward_points,
                        unlocked_at,
                    });
                }
            }
        }

        Ok(newly_unlocked)
    }

    /// Build UserStats from the database for achievement checking.
    async fn build_user_stats(&self, user_id: Uuid) -> ApiResult<gamification::UserStats> {
        // Aggregate exercise results
        let stats = sqlx::query_as::<_, (i64, i64, i64, i32)>(
            r#"
            SELECT
                COALESCE(SUM(CASE WHEN is_correct THEN points_earned ELSE 0 END), 0) as total_points,
                COUNT(*) as total_answered,
                COUNT(*) FILTER (WHERE is_correct) as total_correct,
                0 as placeholder
            FROM exercise_results
            WHERE user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.db)
        .await?;

        // Current streak
        let current_streak: i32 = sqlx::query_scalar(
            r#"
            WITH ranked AS (
                SELECT is_correct, ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
                FROM exercise_results WHERE user_id = $1
            )
            SELECT COUNT(*)::int4 FROM ranked WHERE is_correct = true AND rn <= (
                SELECT COALESCE(MIN(rn) - 1, COUNT(*)) FROM ranked WHERE is_correct = false
            )
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.db)
        .await
        .unwrap_or(0);

        // Longest streak
        let longest_streak: i32 = sqlx::query_scalar(
            "SELECT COALESCE(MAX(streak_count), 0) FROM daily_progress WHERE user_id = $1",
        )
        .bind(user_id)
        .fetch_one(&self.db)
        .await
        .unwrap_or(0);

        // Day streak
        let day_streak: i32 = sqlx::query_scalar(
            r#"
            WITH daily AS (
                SELECT DISTINCT DATE(created_at) as d
                FROM exercise_results WHERE user_id = $1
                ORDER BY d DESC
            ),
            numbered AS (
                SELECT d, ROW_NUMBER() OVER (ORDER BY d DESC) as rn
                FROM daily
            )
            SELECT COUNT(*)::int4 FROM numbered
            WHERE d = CURRENT_DATE - (rn - 1)::int
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.db)
        .await
        .unwrap_or(0);

        // Per-topic stats
        let topic_stats = sqlx::query_as::<_, (String, i64, i64)>(
            r#"
            SELECT topic,
                   COUNT(*) as total,
                   COUNT(*) FILTER (WHERE is_correct) as correct
            FROM exercise_results
            WHERE user_id = $1 AND topic IN ('addition', 'subtraction', 'multiplication', 'division')
            GROUP BY topic
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.db)
        .await?;

        let mut addition_total = 0i64;
        let mut addition_correct = 0i64;
        let mut subtraction_total = 0i64;
        let mut subtraction_correct = 0i64;
        let mut multiplication_total = 0i64;
        let mut multiplication_correct = 0i64;
        let mut division_total = 0i64;
        let mut division_correct = 0i64;

        for (topic, total, correct) in &topic_stats {
            match topic.as_str() {
                "addition" => {
                    addition_total = *total;
                    addition_correct = *correct;
                }
                "subtraction" => {
                    subtraction_total = *total;
                    subtraction_correct = *correct;
                }
                "multiplication" => {
                    multiplication_total = *total;
                    multiplication_correct = *correct;
                }
                "division" => {
                    division_total = *total;
                    division_correct = *correct;
                }
                _ => {}
            }
        }

        // Perfect session count
        let perfect_session_count: i64 = sqlx::query_scalar(
            r#"
            SELECT COUNT(*) FROM practice_sessions
            WHERE user_id = $1
              AND status = 'completed'
              AND total_questions >= 10
              AND correct_count = total_questions
            "#,
        )
        .bind(user_id)
        .fetch_one(&self.db)
        .await
        .unwrap_or(0);

        // Get user level
        let (total_xp, current_level): (i64, i32) = sqlx::query_as(
            "SELECT total_xp, current_level FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_one(&self.db)
        .await?;

        Ok(gamification::UserStats {
            total_answered: stats.1,
            total_correct: stats.2,
            current_streak,
            longest_streak,
            total_points: total_xp,
            day_streak,
            level: current_level,
            addition_total,
            addition_correct,
            subtraction_total,
            subtraction_correct,
            multiplication_total,
            multiplication_correct,
            division_total,
            division_correct,
            fastest_five_ms: None, // TODO: implement fastest-5 tracking
            perfect_session: false,
            perfect_session_count,
        })
    }

    /// Get all themes with unlock status for a user.
    pub async fn get_themes(&self, user_id: Uuid) -> ApiResult<ThemeListResponse> {
        let user = sqlx::query_as::<_, (i64, i32)>(
            "SELECT total_xp, current_level FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?
        .ok_or_else(|| ApiError::NotFound("User not found".to_string()))?;

        let user_xp = user.0;
        let user_level = user.1;

        let themes = sqlx::query_as::<_, ThemeWithStatus>(
            r#"
            SELECT
                t.id, t.name, t.description, t.emoji,
                t.required_level, t.required_xp, t.is_premium,
                CASE WHEN ut.id IS NOT NULL THEN true ELSE false END as is_unlocked,
                COALESCE(ut.is_active, false) as is_active
            FROM unlockable_themes t
            LEFT JOIN user_themes ut ON t.id = ut.theme_id AND ut.user_id = $1
            ORDER BY t.required_level, t.required_xp
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.db)
        .await?;

        let mut active_theme_id = None;
        let theme_responses: Vec<ThemeResponse> = themes
            .into_iter()
            .map(|t| {
                let can_unlock = !t.is_unlocked
                    && user_level >= t.required_level
                    && user_xp >= t.required_xp;

                if t.is_active {
                    active_theme_id = Some(t.id);
                }

                ThemeResponse {
                    id: t.id,
                    name: t.name,
                    description: t.description,
                    emoji: t.emoji,
                    required_level: t.required_level,
                    required_xp: t.required_xp,
                    is_premium: t.is_premium,
                    is_unlocked: t.is_unlocked,
                    is_active: t.is_active,
                    can_unlock,
                }
            })
            .collect();

        Ok(ThemeListResponse {
            themes: theme_responses,
            active_theme_id,
        })
    }

    /// Unlock a theme for a user if they meet the requirements.
    pub async fn unlock_theme(&self, user_id: Uuid, theme_id: Uuid) -> ApiResult<ThemeResponse> {
        let theme = sqlx::query_as::<_, (Uuid, String, String, String, i32, i64, bool)>(
            "SELECT id, name, description, emoji, required_level, required_xp, is_premium FROM unlockable_themes WHERE id = $1",
        )
        .bind(theme_id)
        .fetch_optional(&self.db)
        .await?
        .ok_or_else(|| ApiError::NotFound("Theme not found".to_string()))?;

        let user = sqlx::query_as::<_, (i64, i32)>(
            "SELECT total_xp, current_level FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?
        .ok_or_else(|| ApiError::NotFound("User not found".to_string()))?;

        if user.1 < theme.4 || user.0 < theme.5 {
            return Err(ApiError::BadRequest(
                "You don't meet the requirements to unlock this theme".to_string(),
            ));
        }

        // Insert (ignore conflict)
        sqlx::query(
            r#"
            INSERT INTO user_themes (user_id, theme_id, is_active)
            VALUES ($1, $2, false)
            ON CONFLICT (user_id, theme_id) DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(theme_id)
        .execute(&self.db)
        .await?;

        Ok(ThemeResponse {
            id: theme.0,
            name: theme.1,
            description: theme.2,
            emoji: theme.3,
            required_level: theme.4,
            required_xp: theme.5,
            is_premium: theme.6,
            is_unlocked: true,
            is_active: false,
            can_unlock: false,
        })
    }

    /// Set a theme as active (deactivate all others).
    pub async fn activate_theme(&self, user_id: Uuid, theme_id: Uuid) -> ApiResult<()> {
        // Verify the user has unlocked this theme
        let has_theme: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM user_themes WHERE user_id = $1 AND theme_id = $2)",
        )
        .bind(user_id)
        .bind(theme_id)
        .fetch_one(&self.db)
        .await?;

        if !has_theme {
            return Err(ApiError::BadRequest(
                "You haven't unlocked this theme yet".to_string(),
            ));
        }

        // Deactivate all themes, then activate the selected one
        let mut tx = self.db.begin().await?;

        sqlx::query("UPDATE user_themes SET is_active = false WHERE user_id = $1")
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        sqlx::query(
            "UPDATE user_themes SET is_active = true WHERE user_id = $1 AND theme_id = $2",
        )
        .bind(user_id)
        .bind(theme_id)
        .execute(&mut *tx)
        .await?;

        tx.commit().await?;
        Ok(())
    }

    /// Helper: get the currently active theme for a user.
    async fn get_active_theme(&self, user_id: Uuid) -> ApiResult<Option<ThemeResponse>> {
        let theme = sqlx::query_as::<_, ThemeWithStatus>(
            r#"
            SELECT
                t.id, t.name, t.description, t.emoji,
                t.required_level, t.required_xp, t.is_premium,
                true as is_unlocked,
                true as is_active
            FROM unlockable_themes t
            JOIN user_themes ut ON t.id = ut.theme_id
            WHERE ut.user_id = $1 AND ut.is_active = true
            LIMIT 1
            "#,
        )
        .bind(user_id)
        .fetch_optional(&self.db)
        .await?;

        Ok(theme.map(|t| ThemeResponse {
            id: t.id,
            name: t.name,
            description: t.description,
            emoji: t.emoji,
            required_level: t.required_level,
            required_xp: t.required_xp,
            is_premium: t.is_premium,
            is_unlocked: true,
            is_active: true,
            can_unlock: false,
        }))
    }
}
