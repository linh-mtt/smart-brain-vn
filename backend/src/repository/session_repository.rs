use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::practice_session::{PracticeResult, PracticeSession, SessionStatus};
use crate::error::ApiResult;

// ─── Repository Trait ────────────────────────────────────────────────────────

#[async_trait]
pub trait SessionRepository: Send + Sync {
    async fn create_session(
        &self,
        user_id: Uuid,
        topic: &str,
        difficulty_start: i32,
    ) -> ApiResult<PracticeSession>;

    async fn find_by_id(&self, session_id: Uuid) -> ApiResult<Option<PracticeSession>>;

    async fn update_session(&self, session: &PracticeSession) -> ApiResult<PracticeSession>;

    async fn create_result(&self, result: &PracticeResult) -> ApiResult<PracticeResult>;

    async fn find_results_by_session(
        &self,
        session_id: Uuid,
    ) -> ApiResult<Vec<PracticeResult>>;

    async fn find_sessions_by_user(
        &self,
        user_id: Uuid,
        limit: i64,
    ) -> ApiResult<Vec<PracticeSession>>;
}

// ─── PostgreSQL Implementation ───────────────────────────────────────────────

pub struct PgSessionRepository {
    pool: PgPool,
}

impl PgSessionRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

// ─── Internal DB Row Types ───────────────────────────────────────────────────

#[derive(sqlx::FromRow)]
struct SessionRow {
    id: Uuid,
    user_id: Uuid,
    topic: String,
    status: String,
    total_questions: i32,
    correct_count: i32,
    total_points: i32,
    total_time_ms: i64,
    max_combo: i32,
    current_combo: i32,
    difficulty_start: i32,
    difficulty_end: i32,
    started_at: DateTime<Utc>,
    completed_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

fn row_to_session(row: SessionRow) -> PracticeSession {
    PracticeSession {
        id: row.id,
        user_id: row.user_id,
        topic: row.topic,
        status: SessionStatus::from_str_value(&row.status).unwrap_or(SessionStatus::Active),
        total_questions: row.total_questions,
        correct_count: row.correct_count,
        total_points: row.total_points,
        total_time_ms: row.total_time_ms,
        max_combo: row.max_combo,
        current_combo: row.current_combo,
        difficulty_start: row.difficulty_start,
        difficulty_end: row.difficulty_end,
        started_at: row.started_at,
        completed_at: row.completed_at,
        created_at: row.created_at,
        updated_at: row.updated_at,
    }
}

#[derive(sqlx::FromRow)]
struct ResultRow {
    id: Uuid,
    session_id: Uuid,
    user_id: Uuid,
    question_id: Uuid,
    topic: String,
    difficulty_level: i32,
    question_text: String,
    correct_answer: f64,
    user_answer: f64,
    is_correct: bool,
    points_earned: i32,
    combo_multiplier: f64,
    combo_count: i32,
    time_taken_ms: Option<i32>,
    created_at: DateTime<Utc>,
}

fn row_to_result(row: ResultRow) -> PracticeResult {
    PracticeResult {
        id: row.id,
        session_id: row.session_id,
        user_id: row.user_id,
        question_id: row.question_id,
        topic: row.topic,
        difficulty_level: row.difficulty_level,
        question_text: row.question_text,
        correct_answer: row.correct_answer,
        user_answer: row.user_answer,
        is_correct: row.is_correct,
        points_earned: row.points_earned,
        combo_multiplier: row.combo_multiplier,
        combo_count: row.combo_count,
        time_taken_ms: row.time_taken_ms,
        created_at: row.created_at,
    }
}

// ─── Trait Implementation ────────────────────────────────────────────────────

#[async_trait]
impl SessionRepository for PgSessionRepository {
    async fn create_session(
        &self,
        user_id: Uuid,
        topic: &str,
        difficulty_start: i32,
    ) -> ApiResult<PracticeSession> {
        let row = sqlx::query_as::<_, SessionRow>(
            r#"
            INSERT INTO practice_sessions (user_id, topic, difficulty_start, difficulty_end, status)
            VALUES ($1, $2, $3, $3, 'active')
            RETURNING id, user_id, topic, status::text, total_questions, correct_count,
                      total_points, total_time_ms, max_combo, current_combo,
                      difficulty_start, difficulty_end, started_at, completed_at,
                      created_at, updated_at
            "#,
        )
        .bind(user_id)
        .bind(topic)
        .bind(difficulty_start)
        .fetch_one(&self.pool)
        .await?;

        Ok(row_to_session(row))
    }

    async fn find_by_id(&self, session_id: Uuid) -> ApiResult<Option<PracticeSession>> {
        let row = sqlx::query_as::<_, SessionRow>(
            r#"
            SELECT id, user_id, topic, status::text, total_questions, correct_count,
                   total_points, total_time_ms, max_combo, current_combo,
                   difficulty_start, difficulty_end, started_at, completed_at,
                   created_at, updated_at
            FROM practice_sessions
            WHERE id = $1
            "#,
        )
        .bind(session_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(row_to_session))
    }

    async fn update_session(&self, session: &PracticeSession) -> ApiResult<PracticeSession> {
        let row = sqlx::query_as::<_, SessionRow>(
            r#"
            UPDATE practice_sessions SET
                status = $2::session_status,
                total_questions = $3,
                correct_count = $4,
                total_points = $5,
                total_time_ms = $6,
                max_combo = $7,
                current_combo = $8,
                difficulty_end = $9,
                completed_at = $10
            WHERE id = $1
            RETURNING id, user_id, topic, status::text, total_questions, correct_count,
                      total_points, total_time_ms, max_combo, current_combo,
                      difficulty_start, difficulty_end, started_at, completed_at,
                      created_at, updated_at
            "#,
        )
        .bind(session.id)
        .bind(session.status.as_str())
        .bind(session.total_questions)
        .bind(session.correct_count)
        .bind(session.total_points)
        .bind(session.total_time_ms)
        .bind(session.max_combo)
        .bind(session.current_combo)
        .bind(session.difficulty_end)
        .bind(session.completed_at)
        .fetch_one(&self.pool)
        .await?;

        Ok(row_to_session(row))
    }

    async fn create_result(&self, result: &PracticeResult) -> ApiResult<PracticeResult> {
        let row = sqlx::query_as::<_, ResultRow>(
            r#"
            INSERT INTO practice_results (
                session_id, user_id, question_id, topic, difficulty_level,
                question_text, correct_answer, user_answer, is_correct,
                points_earned, combo_multiplier, combo_count, time_taken_ms
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            RETURNING id, session_id, user_id, question_id, topic, difficulty_level,
                      question_text, correct_answer, user_answer, is_correct,
                      points_earned, combo_multiplier, combo_count, time_taken_ms,
                      created_at
            "#,
        )
        .bind(result.session_id)
        .bind(result.user_id)
        .bind(result.question_id)
        .bind(&result.topic)
        .bind(result.difficulty_level)
        .bind(&result.question_text)
        .bind(result.correct_answer)
        .bind(result.user_answer)
        .bind(result.is_correct)
        .bind(result.points_earned)
        .bind(result.combo_multiplier)
        .bind(result.combo_count)
        .bind(result.time_taken_ms)
        .fetch_one(&self.pool)
        .await?;

        Ok(row_to_result(row))
    }

    async fn find_results_by_session(
        &self,
        session_id: Uuid,
    ) -> ApiResult<Vec<PracticeResult>> {
        let rows = sqlx::query_as::<_, ResultRow>(
            r#"
            SELECT id, session_id, user_id, question_id, topic, difficulty_level,
                   question_text, correct_answer, user_answer, is_correct,
                   points_earned, combo_multiplier, combo_count, time_taken_ms,
                   created_at
            FROM practice_results
            WHERE session_id = $1
            ORDER BY created_at ASC
            "#,
        )
        .bind(session_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_result).collect())
    }

    async fn find_sessions_by_user(
        &self,
        user_id: Uuid,
        limit: i64,
    ) -> ApiResult<Vec<PracticeSession>> {
        let rows = sqlx::query_as::<_, SessionRow>(
            r#"
            SELECT id, user_id, topic, status::text, total_questions, correct_count,
                   total_points, total_time_ms, max_combo, current_combo,
                   difficulty_start, difficulty_end, started_at, completed_at,
                   created_at, updated_at
            FROM practice_sessions
            WHERE user_id = $1
            ORDER BY started_at DESC
            LIMIT $2
            "#,
        )
        .bind(user_id)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(row_to_session).collect())
    }
}
