use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::question::DomainQuestion;
use crate::error::ApiResult;

// ─── Internal sqlx Model ─────────────────────────────────────────────────────

#[derive(Debug, Clone, sqlx::FromRow)]
struct QuestionRow {
    id: Uuid,
    topic: String,
    difficulty_level: i32,
    question_template: String,
    operand_min: i32,
    operand_max: i32,
    explanation_template: String,
    grade_min: i32,
    grade_max: i32,
    active: bool,
    created_at: DateTime<Utc>,
}

fn row_to_domain(row: QuestionRow) -> DomainQuestion {
    DomainQuestion {
        id: row.id,
        topic: row.topic,
        difficulty_level: row.difficulty_level,
        question_template: row.question_template,
        operand_min: row.operand_min,
        operand_max: row.operand_max,
        explanation_template: row.explanation_template,
        grade_min: row.grade_min,
        grade_max: row.grade_max,
        active: row.active,
        created_at: row.created_at,
    }
}

// ─── Repository Trait ────────────────────────────────────────────────────────

#[async_trait]
pub trait QuestionRepository: Send + Sync {
    /// Find questions by topic and difficulty level, filtered by grade range.
    async fn find_by_topic_and_difficulty(
        &self,
        topic: &str,
        difficulty_level: i32,
        grade_level: i32,
        limit: i64,
    ) -> ApiResult<Vec<DomainQuestion>>;

    /// Find all active questions for a topic.
    async fn find_active_by_topic(&self, topic: &str) -> ApiResult<Vec<DomainQuestion>>;

    /// Count active questions for a topic.
    async fn count_by_topic(&self, topic: &str) -> ApiResult<i64>;
}

// ─── PostgreSQL Implementation ───────────────────────────────────────────────

pub struct PgQuestionRepository {
    pool: PgPool,
}

impl PgQuestionRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl QuestionRepository for PgQuestionRepository {
    async fn find_by_topic_and_difficulty(
        &self,
        topic: &str,
        difficulty_level: i32,
        grade_level: i32,
        limit: i64,
    ) -> ApiResult<Vec<DomainQuestion>> {
        let rows = sqlx::query_as::<_, QuestionRow>(
            r#"
            SELECT id, topic, difficulty_level, question_template, operand_min, operand_max,
                   explanation_template, grade_min, grade_max, active, created_at
            FROM question_bank
            WHERE topic = $1
              AND difficulty_level BETWEEN ($2 - 1) AND ($2 + 1)
              AND grade_min <= $3
              AND grade_max >= $3
              AND active = true
            ORDER BY RANDOM()
            LIMIT $4
            "#,
        )
        .bind(topic)
        .bind(difficulty_level)
        .bind(grade_level)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_domain).collect())
    }

    async fn find_active_by_topic(&self, topic: &str) -> ApiResult<Vec<DomainQuestion>> {
        let rows = sqlx::query_as::<_, QuestionRow>(
            r#"
            SELECT id, topic, difficulty_level, question_template, operand_min, operand_max,
                   explanation_template, grade_min, grade_max, active, created_at
            FROM question_bank
            WHERE topic = $1 AND active = true
            ORDER BY difficulty_level
            "#,
        )
        .bind(topic)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_domain).collect())
    }

    async fn count_by_topic(&self, topic: &str) -> ApiResult<i64> {
        let count: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM question_bank WHERE topic = $1 AND active = true",
        )
        .bind(topic)
        .fetch_one(&self.pool)
        .await?;

        Ok(count)
    }
}
