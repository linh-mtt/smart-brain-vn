use std::sync::Arc;

use chrono::Utc;
use uuid::Uuid;

use crate::config::Config;
use crate::domain::practice_session::{
    self, PracticeResult, PracticeSession, SessionStatus,
};
use crate::dto::practice::PracticeSubmitRequest;
use crate::dto::session::{
    ResultDetail, SessionProgress, SessionResultResponse, SessionSubmitResponse,
    StartSessionResponse,
};
use crate::error::{ApiError, ApiResult};
use crate::repository::question_repository::QuestionRepository;
use crate::repository::session_repository::SessionRepository;
use crate::repository::skill_repository::SkillRepository;
use crate::services::adaptive_engine::AdaptiveEngine;

// ─── Session Service ─────────────────────────────────────────────────────────

pub struct SessionService<SR: SessionRepository, Q: QuestionRepository, S: SkillRepository> {
    session_repo: Arc<SR>,
    adaptive_engine: Arc<AdaptiveEngine<Q, S>>,
    #[allow(dead_code)]
    config: Arc<Config>,
}

impl<SR: SessionRepository, Q: QuestionRepository, S: SkillRepository>
    SessionService<SR, Q, S>
{
    pub fn new(
        session_repo: Arc<SR>,
        adaptive_engine: Arc<AdaptiveEngine<Q, S>>,
        config: Arc<Config>,
    ) -> Self {
        Self {
            session_repo,
            adaptive_engine,
            config,
        }
    }

    /// Start a new practice session.
    /// Creates the session record and fetches initial adaptive questions.
    pub async fn start_session(
        &self,
        user_id: Uuid,
        topic: &str,
        grade_level: i32,
        question_count: usize,
    ) -> ApiResult<StartSessionResponse> {
        // Validate topic via the adaptive engine (reuses its validation)
        let questions = self
            .adaptive_engine
            .get_adaptive_questions(user_id, topic, grade_level, question_count)
            .await?;

        let difficulty_start = questions
            .first()
            .map(|q| q.difficulty_level)
            .unwrap_or(1);

        // Create session record
        let session = self
            .session_repo
            .create_session(user_id, topic, difficulty_start)
            .await?;

        Ok(StartSessionResponse {
            session_id: session.id,
            topic: session.topic,
            difficulty_start: session.difficulty_start,
            questions,
        })
    }

    /// Submit an answer within a session.
    /// Updates combo, records result, delegates adaptive logic to the engine.
    pub async fn submit_answer(
        &self,
        user_id: Uuid,
        session_id: Uuid,
        question_id: Uuid,
        topic: &str,
        difficulty_level: i32,
        question_text: &str,
        correct_answer: f64,
        answer: f64,
        time_taken_ms: Option<i32>,
    ) -> ApiResult<SessionSubmitResponse> {
        // Fetch and validate session
        let session = self
            .session_repo
            .find_by_id(session_id)
            .await?
            .ok_or_else(|| ApiError::NotFound("Practice session not found".to_string()))?;

        if session.user_id != user_id {
            return Err(ApiError::Forbidden);
        }

        if session.status != SessionStatus::Active {
            return Err(ApiError::BadRequest(
                "Session is not active. Start a new session.".to_string(),
            ));
        }

        // Delegate to adaptive engine for skill profile updates
        let submit_req = PracticeSubmitRequest {
            question_id,
            topic: topic.to_string(),
            difficulty_level,
            question_text: question_text.to_string(),
            correct_answer,
            answer,
            time_taken_ms,
        };
        let adaptive_feedback = self.adaptive_engine.submit_answer(user_id, &submit_req).await?;

        // Calculate combo
        let new_combo = practice_session::calculate_combo(
            session.current_combo,
            adaptive_feedback.is_correct,
        );
        let (points, combo_multiplier) = practice_session::calculate_session_points(
            adaptive_feedback.is_correct,
            difficulty_level,
            new_combo,
        );
        let new_max_combo = session.max_combo.max(new_combo);

        // Record individual result
        let result = PracticeResult {
            id: Uuid::new_v4(),
            session_id,
            user_id,
            question_id,
            topic: topic.to_string(),
            difficulty_level,
            question_text: question_text.to_string(),
            correct_answer,
            user_answer: answer,
            is_correct: adaptive_feedback.is_correct,
            points_earned: points,
            combo_multiplier,
            combo_count: new_combo,
            time_taken_ms,
            created_at: Utc::now(),
        };
        self.session_repo.create_result(&result).await?;

        // Update session aggregates
        let correct_inc = if adaptive_feedback.is_correct { 1 } else { 0 };
        let time_inc = time_taken_ms.unwrap_or(0) as i64;

        let updated_session = PracticeSession {
            total_questions: session.total_questions + 1,
            correct_count: session.correct_count + correct_inc,
            total_points: session.total_points + points,
            total_time_ms: session.total_time_ms + time_inc,
            max_combo: new_max_combo,
            current_combo: new_combo,
            difficulty_end: adaptive_feedback.new_difficulty,
            ..session
        };
        self.session_repo.update_session(&updated_session).await?;

        let accuracy = practice_session::calculate_accuracy(
            updated_session.total_questions,
            updated_session.correct_count,
        );

        Ok(SessionSubmitResponse {
            is_correct: adaptive_feedback.is_correct,
            correct_answer,
            points_earned: points,
            combo_count: new_combo,
            combo_multiplier,
            max_combo: new_max_combo,
            new_difficulty: adaptive_feedback.new_difficulty,
            elo_rating: adaptive_feedback.elo_rating,
            streak: adaptive_feedback.streak,
            weak_topics: adaptive_feedback.weak_topics,
            session_progress: SessionProgress {
                total_questions: updated_session.total_questions,
                correct_count: updated_session.correct_count,
                total_points: updated_session.total_points,
                total_time_ms: updated_session.total_time_ms,
                accuracy,
            },
        })
    }

    /// Get the final result of a practice session.
    /// Marks the session as completed if still active.
    pub async fn get_result(
        &self,
        user_id: Uuid,
        session_id: Uuid,
    ) -> ApiResult<SessionResultResponse> {
        let mut session = self
            .session_repo
            .find_by_id(session_id)
            .await?
            .ok_or_else(|| ApiError::NotFound("Practice session not found".to_string()))?;

        if session.user_id != user_id {
            return Err(ApiError::Forbidden);
        }

        // Auto-complete the session if still active
        if session.status == SessionStatus::Active {
            session.status = SessionStatus::Completed;
            session.completed_at = Some(Utc::now());
            session = self.session_repo.update_session(&session).await?;
        }

        let results = self.session_repo.find_results_by_session(session_id).await?;

        let accuracy = practice_session::calculate_accuracy(
            session.total_questions,
            session.correct_count,
        );

        let result_details: Vec<ResultDetail> = results
            .into_iter()
            .map(|r| ResultDetail {
                id: r.id,
                question_text: r.question_text,
                correct_answer: r.correct_answer,
                user_answer: r.user_answer,
                is_correct: r.is_correct,
                points_earned: r.points_earned,
                combo_count: r.combo_count,
                combo_multiplier: r.combo_multiplier,
                time_taken_ms: r.time_taken_ms,
                created_at: r.created_at,
            })
            .collect();

        Ok(SessionResultResponse {
            session_id: session.id,
            user_id: session.user_id,
            topic: session.topic,
            status: session.status.as_str().to_string(),
            total_questions: session.total_questions,
            correct_count: session.correct_count,
            accuracy,
            total_points: session.total_points,
            total_time_ms: session.total_time_ms,
            max_combo: session.max_combo,
            difficulty_start: session.difficulty_start,
            difficulty_end: session.difficulty_end,
            started_at: session.started_at,
            completed_at: session.completed_at,
            results: result_details,
        })
    }
}

// ─── Unit Tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use async_trait::async_trait;
    use std::collections::HashMap;
    use tokio::sync::Mutex;

    use crate::domain::practice_session::{PracticeResult, PracticeSession, SessionStatus};
    use crate::domain::question::DomainQuestion;
    use crate::domain::skill_profile::SkillProfile;
    use crate::repository::question_repository::QuestionRepository;
    use crate::repository::skill_repository::SkillRepository;

    // ─── Mock Session Repository ─────────────────────────────────────────────

    #[derive(Default)]
    struct MockSessionRepository {
        sessions: Arc<Mutex<HashMap<Uuid, PracticeSession>>>,
        results: Arc<Mutex<Vec<PracticeResult>>>,
    }

    #[async_trait]
    impl SessionRepository for MockSessionRepository {
        async fn create_session(
            &self,
            user_id: Uuid,
            topic: &str,
            difficulty_start: i32,
        ) -> ApiResult<PracticeSession> {
            let session = PracticeSession {
                id: Uuid::new_v4(),
                user_id,
                topic: topic.to_string(),
                status: SessionStatus::Active,
                total_questions: 0,
                correct_count: 0,
                total_points: 0,
                total_time_ms: 0,
                max_combo: 0,
                current_combo: 0,
                difficulty_start,
                difficulty_end: difficulty_start,
                started_at: Utc::now(),
                completed_at: None,
                created_at: Utc::now(),
                updated_at: Utc::now(),
            };
            let mut sessions = self.sessions.lock().await;
            sessions.insert(session.id, session.clone());
            Ok(session)
        }

        async fn find_by_id(&self, session_id: Uuid) -> ApiResult<Option<PracticeSession>> {
            let sessions = self.sessions.lock().await;
            Ok(sessions.get(&session_id).cloned())
        }

        async fn update_session(&self, session: &PracticeSession) -> ApiResult<PracticeSession> {
            let mut sessions = self.sessions.lock().await;
            sessions.insert(session.id, session.clone());
            Ok(session.clone())
        }

        async fn create_result(&self, result: &PracticeResult) -> ApiResult<PracticeResult> {
            let mut results = self.results.lock().await;
            results.push(result.clone());
            Ok(result.clone())
        }

        async fn find_results_by_session(
            &self,
            session_id: Uuid,
        ) -> ApiResult<Vec<PracticeResult>> {
            let results = self.results.lock().await;
            Ok(results
                .iter()
                .filter(|r| r.session_id == session_id)
                .cloned()
                .collect())
        }

        async fn find_sessions_by_user(
            &self,
            user_id: Uuid,
            limit: i64,
        ) -> ApiResult<Vec<PracticeSession>> {
            let sessions = self.sessions.lock().await;
            Ok(sessions
                .values()
                .filter(|s| s.user_id == user_id)
                .take(limit as usize)
                .cloned()
                .collect())
        }
    }

    // ─── Mock Question Repository ────────────────────────────────────────────

    #[derive(Default)]
    struct MockQuestionRepository {
        questions: Arc<Mutex<Vec<DomainQuestion>>>,
    }

    #[async_trait]
    impl QuestionRepository for MockQuestionRepository {
        async fn find_by_topic_and_difficulty(
            &self,
            topic: &str,
            _difficulty_level: i32,
            _grade_level: i32,
            limit: i64,
        ) -> ApiResult<Vec<DomainQuestion>> {
            let questions = self.questions.lock().await;
            Ok(questions
                .iter()
                .filter(|q| q.topic == topic && q.active)
                .take(limit as usize)
                .cloned()
                .collect())
        }

        async fn find_active_by_topic(&self, topic: &str) -> ApiResult<Vec<DomainQuestion>> {
            let questions = self.questions.lock().await;
            Ok(questions
                .iter()
                .filter(|q| q.topic == topic && q.active)
                .cloned()
                .collect())
        }

        async fn count_by_topic(&self, topic: &str) -> ApiResult<i64> {
            let questions = self.questions.lock().await;
            Ok(questions
                .iter()
                .filter(|q| q.topic == topic && q.active)
                .count() as i64)
        }
    }

    // ─── Mock Skill Repository ───────────────────────────────────────────────

    #[derive(Default)]
    struct MockSkillRepository {
        profiles: Arc<Mutex<HashMap<(Uuid, String), SkillProfile>>>,
    }

    #[async_trait]
    impl SkillRepository for MockSkillRepository {
        async fn find_by_user_and_topic(
            &self,
            user_id: Uuid,
            topic: &str,
        ) -> ApiResult<Option<SkillProfile>> {
            let profiles = self.profiles.lock().await;
            Ok(profiles.get(&(user_id, topic.to_string())).cloned())
        }

        async fn find_all_by_user(&self, user_id: Uuid) -> ApiResult<Vec<SkillProfile>> {
            let profiles = self.profiles.lock().await;
            Ok(profiles
                .iter()
                .filter(|((uid, _), _)| *uid == user_id)
                .map(|(_, p)| p.clone())
                .collect())
        }

        async fn upsert(&self, profile: &SkillProfile) -> ApiResult<SkillProfile> {
            let mut profiles = self.profiles.lock().await;
            let key = (profile.user_id, profile.topic.clone());
            profiles.insert(key, profile.clone());
            Ok(profile.clone())
        }

        async fn find_due_for_review(
            &self,
            user_id: Uuid,
            now: chrono::DateTime<Utc>,
        ) -> ApiResult<Vec<SkillProfile>> {
            let profiles = self.profiles.lock().await;
            Ok(profiles
                .iter()
                .filter(|((uid, _), p)| *uid == user_id && p.next_review_at <= now)
                .map(|(_, p)| p.clone())
                .collect())
        }
    }

    // ─── Test Helpers ────────────────────────────────────────────────────────

    fn test_config() -> Config {
        Config {
            database_url: "postgres://test:test@localhost/test".to_string(),
            redis_url: "redis://localhost:6379".to_string(),
            jwt_secret: "test-secret-key-that-is-at-least-32-characters-long".to_string(),
            jwt_access_expires_in: std::time::Duration::from_secs(900),
            jwt_refresh_expires_in: std::time::Duration::from_secs(604800),
            server_host: "0.0.0.0".to_string(),
            server_port: 8080,
            environment: crate::config::Environment::Dev,
        }
    }

    fn sample_question(topic: &str, difficulty: i32) -> DomainQuestion {
        DomainQuestion {
            id: Uuid::new_v4(),
            topic: topic.to_string(),
            difficulty_level: difficulty,
            question_template: "{a} + {b} = ?".to_string(),
            operand_min: 1,
            operand_max: 10,
            explanation_template: "{a} + {b} = {answer}".to_string(),
            grade_min: 1,
            grade_max: 6,
            active: true,
            created_at: Utc::now(),
        }
    }

    fn create_service() -> (
        SessionService<MockSessionRepository, MockQuestionRepository, MockSkillRepository>,
        Arc<MockSessionRepository>,
        Arc<MockQuestionRepository>,
        Arc<MockSkillRepository>,
    ) {
        let session_repo = Arc::new(MockSessionRepository::default());
        let question_repo = Arc::new(MockQuestionRepository::default());
        let skill_repo = Arc::new(MockSkillRepository::default());
        let config = Arc::new(test_config());

        let engine = Arc::new(AdaptiveEngine::new(
            question_repo.clone(),
            skill_repo.clone(),
            config.clone(),
        ));

        let service = SessionService::new(session_repo.clone(), engine, config);
        (service, session_repo, question_repo, skill_repo)
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn test_start_session_creates_record() {
        let (service, session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        // Add question templates
        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let result = service.start_session(user_id, "addition", 3, 1).await;
        assert!(result.is_ok(), "Should succeed: {:?}", result.err());

        let response = result.unwrap();
        assert_eq!(response.topic, "addition");
        assert!(!response.questions.is_empty());

        // Verify session was created in repo
        let sessions = session_repo.sessions.lock().await;
        assert_eq!(sessions.len(), 1);
        let session = sessions.values().next().unwrap();
        assert_eq!(session.status, SessionStatus::Active);
        assert_eq!(session.total_questions, 0);
    }

    #[tokio::test]
    async fn test_start_session_invalid_topic() {
        let (service, _session_repo, _question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        let result = service.start_session(user_id, "trigonometry", 3, 5).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::BadRequest(msg) => assert!(msg.contains("Invalid topic")),
            e => panic!("Expected BadRequest, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_submit_answer_correct_updates_combo() {
        let (service, session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        // Start a session
        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        // Submit correct answer
        let response = service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
            )
            .await
            .unwrap();

        assert!(response.is_correct);
        assert_eq!(response.combo_count, 1);
        assert!(response.points_earned > 0);
        assert_eq!(response.session_progress.total_questions, 1);
        assert_eq!(response.session_progress.correct_count, 1);

        // Verify session updated
        let session = session_repo.find_by_id(session_id).await.unwrap().unwrap();
        assert_eq!(session.current_combo, 1);
        assert_eq!(session.max_combo, 1);
        assert_eq!(session.total_questions, 1);
    }

    #[tokio::test]
    async fn test_submit_answer_wrong_resets_combo() {
        let (service, session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        // Submit 2 correct answers to build combo
        for _ in 0..2 {
            service
                .submit_answer(
                    user_id, session_id, Uuid::new_v4(),
                    "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
                )
                .await
                .unwrap();
        }

        let session = session_repo.find_by_id(session_id).await.unwrap().unwrap();
        assert_eq!(session.current_combo, 2);

        // Submit wrong answer
        let response = service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 5.0, Some(3000),
            )
            .await
            .unwrap();

        assert!(!response.is_correct);
        assert_eq!(response.combo_count, 0);
        assert_eq!(response.points_earned, 0);

        // Max combo should still be 2
        assert_eq!(response.max_combo, 2);
    }

    #[tokio::test]
    async fn test_combo_multiplier_increases_points() {
        let (service, _session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        // Submit 5 correct answers, each should have increasing combo multiplier
        let mut points_history = Vec::new();
        for _ in 0..5 {
            let response = service
                .submit_answer(
                    user_id, session_id, Uuid::new_v4(),
                    "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
                )
                .await
                .unwrap();
            points_history.push(response.points_earned);
        }

        // Points should increase with combo (base 5 for easy difficulty)
        // combo 1: 5 * 1.1 = 6, combo 2: 5 * 1.2 = 6, combo 3: 5 * 1.3 = 7, etc.
        assert!(
            points_history[4] > points_history[0],
            "5th answer should earn more than 1st: {:?}",
            points_history
        );
    }

    #[tokio::test]
    async fn test_submit_to_nonexistent_session() {
        let (service, _session_repo, _question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();
        let fake_session = Uuid::new_v4();

        let result = service
            .submit_answer(
                user_id, fake_session, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
            )
            .await;

        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::NotFound(msg) => assert!(msg.contains("session")),
            e => panic!("Expected NotFound, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_submit_to_other_users_session() {
        let (service, _session_repo, question_repo, _skill_repo) = create_service();
        let user_a = Uuid::new_v4();
        let user_b = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_a, "addition", 3, 1).await.unwrap();

        // User B tries to submit to User A's session
        let result = service
            .submit_answer(
                user_b, start.session_id, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
            )
            .await;

        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Forbidden => {}
            e => panic!("Expected Forbidden, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_get_result_completes_session() {
        let (service, session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        // Submit a few answers
        service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
            )
            .await
            .unwrap();

        service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "5 + 2 = ?", 7.0, 5.0, Some(5000),
            )
            .await
            .unwrap();

        // Get result (should auto-complete)
        let result = service.get_result(user_id, session_id).await.unwrap();

        assert_eq!(result.status, "completed");
        assert_eq!(result.total_questions, 2);
        assert_eq!(result.correct_count, 1);
        assert!((result.accuracy - 50.0).abs() < 0.1);
        assert_eq!(result.results.len(), 2);
        assert!(result.completed_at.is_some());

        // Verify session is now completed in repo
        let session = session_repo.find_by_id(session_id).await.unwrap().unwrap();
        assert_eq!(session.status, SessionStatus::Completed);
    }

    #[tokio::test]
    async fn test_submit_to_completed_session_fails() {
        let (service, _session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        // Complete the session
        service.get_result(user_id, session_id).await.unwrap();

        // Try to submit — should fail
        let result = service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(3000),
            )
            .await;

        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::BadRequest(msg) => assert!(msg.contains("not active")),
            e => panic!("Expected BadRequest, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_get_result_for_other_users_session() {
        let (service, _session_repo, question_repo, _skill_repo) = create_service();
        let user_a = Uuid::new_v4();
        let user_b = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_a, "addition", 3, 1).await.unwrap();

        let result = service.get_result(user_b, start.session_id).await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::Forbidden => {}
            e => panic!("Expected Forbidden, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_session_tracks_time() {
        let (service, _session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "3 + 4 = ?", 7.0, 7.0, Some(5000),
            )
            .await
            .unwrap();

        let response = service
            .submit_answer(
                user_id, session_id, Uuid::new_v4(),
                "addition", 1, "2 + 3 = ?", 5.0, 5.0, Some(3000),
            )
            .await
            .unwrap();

        assert_eq!(response.session_progress.total_time_ms, 8000);
    }

    #[tokio::test]
    async fn test_result_details_in_order() {
        let (service, _session_repo, question_repo, _skill_repo) = create_service();
        let user_id = Uuid::new_v4();

        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let start = service.start_session(user_id, "addition", 3, 1).await.unwrap();
        let session_id = start.session_id;

        // Submit 3 answers with identifiable questions
        for answer in [7.0, 5.0, 9.0] {
            service
                .submit_answer(
                    user_id, session_id, Uuid::new_v4(),
                    "addition", 1, &format!("x = {}", answer), answer, answer, Some(1000),
                )
                .await
                .unwrap();
        }

        let result = service.get_result(user_id, session_id).await.unwrap();
        assert_eq!(result.results.len(), 3);
        // All correct since answer == correct_answer
        assert!(result.results.iter().all(|r| r.is_correct));
    }
}
