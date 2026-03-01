use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::skill_profile::SkillProfile;
use crate::error::ApiResult;

// ─── Internal sqlx Model ─────────────────────────────────────────────────────

#[derive(Debug, Clone, sqlx::FromRow)]
struct SkillProfileRow {
    id: Uuid,
    user_id: Uuid,
    topic: String,
    current_difficulty: i32,
    elo_rating: f64,
    recent_accuracy: f64,
    last_n_results: serde_json::Value,
    consecutive_correct: i32,
    consecutive_wrong: i32,
    next_review_at: DateTime<Utc>,
    review_interval_days: f64,
    ease_factor: f64,
    total_attempts: i32,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

fn row_to_domain(row: SkillProfileRow) -> SkillProfile {
    let last_n_results: Vec<bool> = serde_json::from_value(row.last_n_results).unwrap_or_default();

    SkillProfile {
        id: row.id,
        user_id: row.user_id,
        topic: row.topic,
        current_difficulty: row.current_difficulty,
        elo_rating: row.elo_rating,
        recent_accuracy: row.recent_accuracy,
        last_n_results,
        consecutive_correct: row.consecutive_correct,
        consecutive_wrong: row.consecutive_wrong,
        next_review_at: row.next_review_at,
        review_interval_days: row.review_interval_days,
        ease_factor: row.ease_factor,
        total_attempts: row.total_attempts,
        created_at: row.created_at,
        updated_at: row.updated_at,
    }
}

// ─── Repository Trait ────────────────────────────────────────────────────────

#[async_trait]
pub trait SkillRepository: Send + Sync {
    /// Find skill profile for a specific user and topic.
    async fn find_by_user_and_topic(
        &self,
        user_id: Uuid,
        topic: &str,
    ) -> ApiResult<Option<SkillProfile>>;

    /// Find all skill profiles for a user.
    async fn find_all_by_user(&self, user_id: Uuid) -> ApiResult<Vec<SkillProfile>>;

    /// Create or update a skill profile. Returns the upserted profile.
    async fn upsert(&self, profile: &SkillProfile) -> ApiResult<SkillProfile>;

    /// Find profiles due for spaced repetition review.
    async fn find_due_for_review(
        &self,
        user_id: Uuid,
        now: DateTime<Utc>,
    ) -> ApiResult<Vec<SkillProfile>>;
}

// ─── PostgreSQL Implementation ───────────────────────────────────────────────

pub struct PgSkillRepository {
    pool: PgPool,
}

impl PgSkillRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl SkillRepository for PgSkillRepository {
    async fn find_by_user_and_topic(
        &self,
        user_id: Uuid,
        topic: &str,
    ) -> ApiResult<Option<SkillProfile>> {
        let row = sqlx::query_as::<_, SkillProfileRow>(
            r#"
            SELECT id, user_id, topic, current_difficulty, elo_rating, recent_accuracy,
                   last_n_results, consecutive_correct, consecutive_wrong, next_review_at,
                   review_interval_days, ease_factor, total_attempts, created_at, updated_at
            FROM skill_profiles
            WHERE user_id = $1 AND topic = $2
            "#,
        )
        .bind(user_id)
        .bind(topic)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(row_to_domain))
    }

    async fn find_all_by_user(&self, user_id: Uuid) -> ApiResult<Vec<SkillProfile>> {
        let rows = sqlx::query_as::<_, SkillProfileRow>(
            r#"
            SELECT id, user_id, topic, current_difficulty, elo_rating, recent_accuracy,
                   last_n_results, consecutive_correct, consecutive_wrong, next_review_at,
                   review_interval_days, ease_factor, total_attempts, created_at, updated_at
            FROM skill_profiles
            WHERE user_id = $1
            ORDER BY topic
            "#,
        )
        .bind(user_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_domain).collect())
    }

    async fn upsert(&self, profile: &SkillProfile) -> ApiResult<SkillProfile> {
        let last_n_json = serde_json::to_value(&profile.last_n_results)
            .unwrap_or_else(|_| serde_json::json!([]));

        let row = sqlx::query_as::<_, SkillProfileRow>(
            r#"
            INSERT INTO skill_profiles (
                user_id, topic, current_difficulty, elo_rating, recent_accuracy,
                last_n_results, consecutive_correct, consecutive_wrong, next_review_at,
                review_interval_days, ease_factor, total_attempts
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            ON CONFLICT (user_id, topic)
            DO UPDATE SET
                current_difficulty = EXCLUDED.current_difficulty,
                elo_rating = EXCLUDED.elo_rating,
                recent_accuracy = EXCLUDED.recent_accuracy,
                last_n_results = EXCLUDED.last_n_results,
                consecutive_correct = EXCLUDED.consecutive_correct,
                consecutive_wrong = EXCLUDED.consecutive_wrong,
                next_review_at = EXCLUDED.next_review_at,
                review_interval_days = EXCLUDED.review_interval_days,
                ease_factor = EXCLUDED.ease_factor,
                total_attempts = EXCLUDED.total_attempts
            RETURNING id, user_id, topic, current_difficulty, elo_rating, recent_accuracy,
                      last_n_results, consecutive_correct, consecutive_wrong, next_review_at,
                      review_interval_days, ease_factor, total_attempts, created_at, updated_at
            "#,
        )
        .bind(profile.user_id)
        .bind(&profile.topic)
        .bind(profile.current_difficulty)
        .bind(profile.elo_rating)
        .bind(profile.recent_accuracy)
        .bind(&last_n_json)
        .bind(profile.consecutive_correct)
        .bind(profile.consecutive_wrong)
        .bind(profile.next_review_at)
        .bind(profile.review_interval_days)
        .bind(profile.ease_factor)
        .bind(profile.total_attempts)
        .fetch_one(&self.pool)
        .await?;

        Ok(row_to_domain(row))
    }

    async fn find_due_for_review(
        &self,
        user_id: Uuid,
        now: DateTime<Utc>,
    ) -> ApiResult<Vec<SkillProfile>> {
        let rows = sqlx::query_as::<_, SkillProfileRow>(
            r#"
            SELECT id, user_id, topic, current_difficulty, elo_rating, recent_accuracy,
                   last_n_results, consecutive_correct, consecutive_wrong, next_review_at,
                   review_interval_days, ease_factor, total_attempts, created_at, updated_at
            FROM skill_profiles
            WHERE user_id = $1 AND next_review_at <= $2
            ORDER BY next_review_at ASC
            "#,
        )
        .bind(user_id)
        .bind(now)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_domain).collect())
    }
}
