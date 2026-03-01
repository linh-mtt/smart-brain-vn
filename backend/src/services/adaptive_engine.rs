use std::sync::Arc;

use chrono::{Duration, Utc};
use rand::Rng;
use uuid::Uuid;

use crate::config::Config;
use crate::domain::question::DomainQuestion;
use crate::domain::skill_profile::{
    self, SkillProfile,
};
use crate::dto::practice::{AdaptiveQuestionResponse, PracticeFeedbackResponse, PracticeSubmitRequest};
use crate::error::{ApiError, ApiResult};
use crate::repository::question_repository::QuestionRepository;
use crate::repository::skill_repository::SkillRepository;
use crate::services::math_engine::MathTopic;

// ─── Adaptive Engine Service ─────────────────────────────────────────────────

pub struct AdaptiveEngine<Q: QuestionRepository, S: SkillRepository> {
    question_repo: Arc<Q>,
    skill_repo: Arc<S>,
    #[allow(dead_code)]
    config: Arc<Config>,
}

impl<Q: QuestionRepository, S: SkillRepository> AdaptiveEngine<Q, S> {
    pub fn new(question_repo: Arc<Q>, skill_repo: Arc<S>, config: Arc<Config>) -> Self {
        Self {
            question_repo,
            skill_repo,
            config,
        }
    }

    /// Get adaptive questions for a user on a specific topic.
    /// Creates a skill profile if none exists.
    pub async fn get_adaptive_questions(
        &self,
        user_id: Uuid,
        topic: &str,
        grade_level: i32,
        count: usize,
    ) -> ApiResult<Vec<AdaptiveQuestionResponse>> {
        // Validate topic
        MathTopic::from_str_value(topic).ok_or_else(|| {
            ApiError::BadRequest(format!(
                "Invalid topic: {}. Use: addition, subtraction, multiplication, division",
                topic
            ))
        })?;

        // Get or create skill profile
        let profile = match self.skill_repo.find_by_user_and_topic(user_id, topic).await? {
            Some(p) => p,
            None => {
                let new_profile = SkillProfile {
                    id: Uuid::new_v4(),
                    user_id,
                    topic: topic.to_string(),
                    current_difficulty: 1,
                    elo_rating: 1000.0,
                    recent_accuracy: 0.0,
                    last_n_results: vec![],
                    consecutive_correct: 0,
                    consecutive_wrong: 0,
                    next_review_at: Utc::now(),
                    review_interval_days: 1.0,
                    ease_factor: 2.5,
                    total_attempts: 0,
                    created_at: Utc::now(),
                    updated_at: Utc::now(),
                };
                self.skill_repo.upsert(&new_profile).await?
            }
        };

        // Fetch question templates from the bank
        let templates = self
            .question_repo
            .find_by_topic_and_difficulty(topic, profile.current_difficulty, grade_level, count as i64)
            .await?;

        // If no templates found at this difficulty, fall back to any available
        let templates = if templates.is_empty() {
            let all = self.question_repo.find_active_by_topic(topic).await?;
            if all.is_empty() {
                return Err(ApiError::NotFound(format!(
                    "No questions available for topic: {}",
                    topic
                )));
            }
            // Take `count` from available, preferring closest to current difficulty
            let mut sorted = all;
            let target = profile.current_difficulty;
            sorted.sort_by_key(|q| (q.difficulty_level - target).abs());
            sorted.into_iter().take(count).collect()
        } else {
            templates
        };

        // Generate actual problems from templates
        let mut rng = rand::thread_rng();
        let questions: Vec<AdaptiveQuestionResponse> = templates
            .iter()
            .map(|t| generate_from_template(&mut rng, t))
            .collect();

        Ok(questions)
    }

    /// Submit an answer and update the skill profile adaptively.
    pub async fn submit_answer(
        &self,
        user_id: Uuid,
        req: &PracticeSubmitRequest,
    ) -> ApiResult<PracticeFeedbackResponse> {
        // Validate topic
        MathTopic::from_str_value(&req.topic).ok_or_else(|| {
            ApiError::BadRequest(format!("Invalid topic: {}", req.topic))
        })?;

        // Check answer (tolerance 0.01)
        let is_correct = (req.answer - req.correct_answer).abs() < 0.01;

        // Get or create skill profile
        let profile = match self.skill_repo.find_by_user_and_topic(user_id, &req.topic).await? {
            Some(p) => p,
            None => {
                let new_profile = SkillProfile {
                    id: Uuid::new_v4(),
                    user_id,
                    topic: req.topic.clone(),
                    current_difficulty: req.difficulty_level,
                    elo_rating: 1000.0,
                    recent_accuracy: 0.0,
                    last_n_results: vec![],
                    consecutive_correct: 0,
                    consecutive_wrong: 0,
                    next_review_at: Utc::now(),
                    review_interval_days: 1.0,
                    ease_factor: 2.5,
                    total_attempts: 0,
                    created_at: Utc::now(),
                    updated_at: Utc::now(),
                };
                self.skill_repo.upsert(&new_profile).await?
            }
        };

        // Calculate adaptive updates
        let new_difficulty = skill_profile::calculate_new_difficulty(&profile, is_correct);
        let new_elo = skill_profile::update_elo(profile.elo_rating, req.difficulty_level, is_correct);
        let quality = skill_profile::answer_to_quality(is_correct, req.time_taken_ms);
        let (new_interval, new_ease) =
            skill_profile::update_spaced_repetition(profile.review_interval_days, profile.ease_factor, quality);

        // Update sliding window
        let new_results = skill_profile::update_last_n_results(&profile.last_n_results, is_correct);
        let new_accuracy = skill_profile::calculate_recent_accuracy(&new_results);

        // Calculate streaks
        let new_consecutive_correct = if is_correct {
            profile.consecutive_correct + 1
        } else {
            0
        };
        let new_consecutive_wrong = if !is_correct {
            profile.consecutive_wrong + 1
        } else {
            0
        };

        // Build next review time
        let interval_seconds = (new_interval * 86400.0) as i64;
        let next_review = Utc::now() + Duration::seconds(interval_seconds);

        // Upsert updated profile
        let updated_profile = SkillProfile {
            id: profile.id,
            user_id,
            topic: req.topic.clone(),
            current_difficulty: new_difficulty,
            elo_rating: new_elo,
            recent_accuracy: new_accuracy,
            last_n_results: new_results,
            consecutive_correct: new_consecutive_correct,
            consecutive_wrong: new_consecutive_wrong,
            next_review_at: next_review,
            review_interval_days: new_interval,
            ease_factor: new_ease,
            total_attempts: profile.total_attempts + 1,
            created_at: profile.created_at,
            updated_at: Utc::now(),
        };

        self.skill_repo.upsert(&updated_profile).await?;

        // Detect weak topics across all user profiles
        let all_profiles = self.skill_repo.find_all_by_user(user_id).await?;
        let weak_topics = skill_profile::detect_weak_topics(&all_profiles);

        // Calculate points using existing gamification
        let difficulty = match req.difficulty_level {
            1..=3 => crate::services::math_engine::Difficulty::Easy,
            4..=7 => crate::services::math_engine::Difficulty::Medium,
            _ => crate::services::math_engine::Difficulty::Hard,
        };
        let streak = if is_correct { new_consecutive_correct } else { 0 };
        let points_earned =
            crate::services::gamification::calculate_points(is_correct, &difficulty, streak);

        Ok(PracticeFeedbackResponse {
            is_correct,
            correct_answer: req.correct_answer,
            points_earned,
            explanation: req.question_text.clone(),
            new_difficulty,
            elo_rating: (new_elo * 10.0).round() / 10.0,
            weak_topics,
            streak: new_consecutive_correct,
        })
    }
}

// ─── Question Generation from Templates ──────────────────────────────────────

fn generate_from_template(rng: &mut impl Rng, template: &DomainQuestion) -> AdaptiveQuestionResponse {
    let topic = template.topic.as_str();
    let min = template.operand_min;
    let max = template.operand_max;

    let (a, b, answer) = match topic {
        "addition" => {
            let a = rng.gen_range(min..=max);
            let b = rng.gen_range(min..=max);
            (a, b, (a + b) as f64)
        }
        "subtraction" => {
            let b = rng.gen_range(min..=max);
            let a = rng.gen_range(b..=max.max(b));
            (a, b, (a - b) as f64)
        }
        "multiplication" => {
            let a = rng.gen_range(min..=max);
            let b = rng.gen_range(min..=max);
            (a, b, (a * b) as f64)
        }
        "division" => {
            // Generate clean division: pick divisor and result, compute dividend
            let divisor = rng.gen_range(min.max(1)..=max.max(1));
            let result = rng.gen_range(1..=max.max(1));
            let dividend = divisor * result;
            (dividend, divisor, result as f64)
        }
        _ => {
            let a = rng.gen_range(min..=max);
            let b = rng.gen_range(min..=max);
            (a, b, (a + b) as f64)
        }
    };

    let question_text = template
        .question_template
        .replace("{a}", &a.to_string())
        .replace("{b}", &b.to_string());

    let explanation = template
        .explanation_template
        .replace("{a}", &a.to_string())
        .replace("{b}", &b.to_string())
        .replace("{answer}", &format_answer(answer));

    let options = generate_options(rng, answer);

    AdaptiveQuestionResponse {
        id: Uuid::new_v4(),
        question_text,
        correct_answer: answer,
        options,
        explanation,
        topic: template.topic.clone(),
        difficulty_level: template.difficulty_level,
    }
}

fn format_answer(answer: f64) -> String {
    if answer == answer.floor() {
        format!("{}", answer as i64)
    } else {
        format!("{:.2}", answer)
    }
}

fn generate_options(rng: &mut impl Rng, correct: f64) -> Vec<String> {
    let mut options: Vec<f64> = vec![correct];
    let range_offset = if correct.abs() < 10.0 {
        5.0
    } else {
        correct.abs() * 0.3
    };

    while options.len() < 4 {
        let wrong = if correct == correct.floor() {
            let offset = rng.gen_range(1..=(range_offset.max(3.0) as i64));
            let sign = if rng.gen_bool(0.5) { 1 } else { -1 };
            let candidate = correct + (offset * sign) as f64;
            if candidate < 0.0 && correct >= 0.0 {
                correct + offset as f64
            } else {
                candidate
            }
        } else {
            let offset = rng.gen_range(1..=30) as f64 / 100.0 * range_offset;
            let sign: f64 = if rng.gen_bool(0.5) { 1.0 } else { -1.0 };
            ((correct + offset * sign) * 100.0).round() / 100.0
        };

        if !options.iter().any(|o| (o - wrong).abs() < 0.001) {
            options.push(wrong);
        }
    }

    // Shuffle
    for i in (1..options.len()).rev() {
        let j = rng.gen_range(0..=i);
        options.swap(i, j);
    }

    options
        .iter()
        .map(|v| {
            if *v == v.floor() {
                format!("{}", *v as i64)
            } else {
                format!("{:.2}", v)
            }
        })
        .collect()
}

// ─── Unit Tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use async_trait::async_trait;
    use chrono::Utc;
    use std::collections::HashMap;
    use tokio::sync::Mutex;

    use crate::domain::question::DomainQuestion;
    use crate::domain::skill_profile::SkillProfile;

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
            let filtered: Vec<DomainQuestion> = questions
                .iter()
                .filter(|q| q.topic == topic && q.active)
                .take(limit as usize)
                .cloned()
                .collect();
            Ok(filtered)
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
            let stored = profile.clone();
            profiles.insert(key, stored.clone());
            Ok(stored)
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

    fn create_engine() -> (
        AdaptiveEngine<MockQuestionRepository, MockSkillRepository>,
        Arc<MockQuestionRepository>,
        Arc<MockSkillRepository>,
    ) {
        let question_repo = Arc::new(MockQuestionRepository::default());
        let skill_repo = Arc::new(MockSkillRepository::default());
        let config = Arc::new(test_config());
        let engine = AdaptiveEngine::new(question_repo.clone(), skill_repo.clone(), config);
        (engine, question_repo, skill_repo)
    }

    fn make_profile(user_id: Uuid, topic: &str) -> SkillProfile {
        SkillProfile {
            id: Uuid::new_v4(),
            user_id,
            topic: topic.to_string(),
            current_difficulty: 3,
            elo_rating: 1000.0,
            recent_accuracy: 70.0,
            last_n_results: vec![true, true, false, true, true],
            consecutive_correct: 2,
            consecutive_wrong: 0,
            next_review_at: Utc::now(),
            review_interval_days: 1.0,
            ease_factor: 2.5,
            total_attempts: 10,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn test_get_questions_creates_profile_if_missing() {
        let (engine, question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        // Add a question template
        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 1));

        let result = engine
            .get_adaptive_questions(user_id, "addition", 3, 1)
            .await;
        assert!(result.is_ok(), "Should succeed: {:?}", result.err());

        // Verify profile was created
        let profile = skill_repo
            .find_by_user_and_topic(user_id, "addition")
            .await
            .unwrap();
        assert!(profile.is_some());
        assert_eq!(profile.unwrap().current_difficulty, 1);
    }

    #[tokio::test]
    async fn test_get_questions_uses_profile_difficulty() {
        let (engine, question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        // Pre-create a profile at difficulty 5
        let mut profile = make_profile(user_id, "addition");
        profile.current_difficulty = 5;
        skill_repo.upsert(&profile).await.unwrap();

        // Add templates
        question_repo
            .questions
            .lock()
            .await
            .push(sample_question("addition", 5));

        let questions = engine
            .get_adaptive_questions(user_id, "addition", 3, 1)
            .await
            .unwrap();
        assert_eq!(questions.len(), 1);
        assert_eq!(questions[0].topic, "addition");
    }

    #[tokio::test]
    async fn test_submit_correct_answer_updates_profile() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        // Pre-create a profile
        let profile = make_profile(user_id, "addition");
        skill_repo.upsert(&profile).await.unwrap();

        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "addition".to_string(),
            difficulty_level: 3,
            question_text: "5 + 3 = ?".to_string(),
            correct_answer: 8.0,
            answer: 8.0, // correct!
            time_taken_ms: Some(3000),
        };

        let result = engine.submit_answer(user_id, &req).await;
        assert!(result.is_ok(), "Submit should succeed: {:?}", result.err());

        let feedback = result.unwrap();
        assert!(feedback.is_correct);
        assert_eq!(feedback.correct_answer, 8.0);
        assert!(feedback.points_earned > 0);
        assert_eq!(feedback.streak, 3); // was 2, now 3

        // Verify profile was updated
        let updated = skill_repo
            .find_by_user_and_topic(user_id, "addition")
            .await
            .unwrap()
            .unwrap();
        assert_eq!(updated.consecutive_correct, 3);
        assert_eq!(updated.consecutive_wrong, 0);
        assert_eq!(updated.total_attempts, 11);
    }

    #[tokio::test]
    async fn test_submit_wrong_answer_updates_profile() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        let profile = make_profile(user_id, "addition");
        skill_repo.upsert(&profile).await.unwrap();

        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "addition".to_string(),
            difficulty_level: 3,
            question_text: "5 + 3 = ?".to_string(),
            correct_answer: 8.0,
            answer: 7.0, // wrong!
            time_taken_ms: Some(5000),
        };

        let feedback = engine.submit_answer(user_id, &req).await.unwrap();
        assert!(!feedback.is_correct);
        assert_eq!(feedback.streak, 0);

        let updated = skill_repo
            .find_by_user_and_topic(user_id, "addition")
            .await
            .unwrap()
            .unwrap();
        assert_eq!(updated.consecutive_correct, 0);
        assert_eq!(updated.consecutive_wrong, 1);
    }

    #[tokio::test]
    async fn test_difficulty_increases_on_streak() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        // Profile with 2 consecutive correct — one more will trigger level up
        let mut profile = make_profile(user_id, "addition");
        profile.current_difficulty = 3;
        profile.consecutive_correct = 2;
        skill_repo.upsert(&profile).await.unwrap();

        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "addition".to_string(),
            difficulty_level: 3,
            question_text: "5 + 3 = ?".to_string(),
            correct_answer: 8.0,
            answer: 8.0,
            time_taken_ms: Some(3000),
        };

        let feedback = engine.submit_answer(user_id, &req).await.unwrap();
        assert_eq!(feedback.new_difficulty, 4); // went from 3 to 4
    }

    #[tokio::test]
    async fn test_difficulty_decreases_on_consecutive_wrong() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        // Profile with 1 consecutive wrong — one more will trigger level down
        let mut profile = make_profile(user_id, "subtraction");
        profile.current_difficulty = 5;
        profile.consecutive_wrong = 1;
        profile.consecutive_correct = 0;
        skill_repo.upsert(&profile).await.unwrap();

        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "subtraction".to_string(),
            difficulty_level: 5,
            question_text: "10 - 7 = ?".to_string(),
            correct_answer: 3.0,
            answer: 5.0, // wrong
            time_taken_ms: Some(10000),
        };

        let feedback = engine.submit_answer(user_id, &req).await.unwrap();
        assert_eq!(feedback.new_difficulty, 4); // went from 5 to 4
    }

    #[tokio::test]
    async fn test_elo_increases_on_correct() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        let profile = make_profile(user_id, "multiplication");
        let original_elo = profile.elo_rating;
        skill_repo.upsert(&profile).await.unwrap();

        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "multiplication".to_string(),
            difficulty_level: 3,
            question_text: "4 × 3 = ?".to_string(),
            correct_answer: 12.0,
            answer: 12.0,
            time_taken_ms: Some(4000),
        };

        let feedback = engine.submit_answer(user_id, &req).await.unwrap();
        assert!(
            feedback.elo_rating > original_elo,
            "Elo should increase on correct answer: {} > {}",
            feedback.elo_rating,
            original_elo
        );
    }

    #[tokio::test]
    async fn test_elo_decreases_on_wrong() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        let profile = make_profile(user_id, "division");
        let original_elo = profile.elo_rating;
        skill_repo.upsert(&profile).await.unwrap();

        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "division".to_string(),
            difficulty_level: 3,
            question_text: "12 ÷ 4 = ?".to_string(),
            correct_answer: 3.0,
            answer: 4.0,
            time_taken_ms: Some(8000),
        };

        let feedback = engine.submit_answer(user_id, &req).await.unwrap();
        assert!(
            feedback.elo_rating < original_elo,
            "Elo should decrease on wrong answer: {} < {}",
            feedback.elo_rating,
            original_elo
        );
    }

    #[tokio::test]
    async fn test_weak_topic_detection() {
        let (engine, _question_repo, skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        // Create a strong profile for addition
        let mut strong = make_profile(user_id, "addition");
        strong.recent_accuracy = 90.0;
        strong.total_attempts = 20;
        skill_repo.upsert(&strong).await.unwrap();

        // Create a weak profile for division
        let mut weak = make_profile(user_id, "division");
        weak.recent_accuracy = 30.0;
        weak.total_attempts = 10;
        weak.consecutive_wrong = 1;
        weak.consecutive_correct = 0;
        skill_repo.upsert(&weak).await.unwrap();

        // Submit a wrong answer for division — triggers weak detection
        let req = PracticeSubmitRequest {
            question_id: Uuid::new_v4(),
            topic: "division".to_string(),
            difficulty_level: 3,
            question_text: "12 ÷ 3 = ?".to_string(),
            correct_answer: 4.0,
            answer: 5.0,
            time_taken_ms: Some(15000),
        };

        let feedback = engine.submit_answer(user_id, &req).await.unwrap();
        assert!(
            feedback.weak_topics.contains(&"division".to_string()),
            "Division should be detected as weak: {:?}",
            feedback.weak_topics
        );
        assert!(
            !feedback.weak_topics.contains(&"addition".to_string()),
            "Addition should not be weak"
        );
    }

    #[tokio::test]
    async fn test_spaced_repetition_interval_update() {
        let profile = SkillProfile {
            id: Uuid::new_v4(),
            user_id: Uuid::new_v4(),
            topic: "addition".to_string(),
            current_difficulty: 3,
            elo_rating: 1000.0,
            recent_accuracy: 80.0,
            last_n_results: vec![true, true, true, true],
            consecutive_correct: 4,
            consecutive_wrong: 0,
            next_review_at: Utc::now(),
            review_interval_days: 6.0,
            ease_factor: 2.5,
            total_attempts: 10,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        // Quality 5 (correct + fast) on a 6-day interval
        let (new_interval, new_ease) =
            skill_profile::update_spaced_repetition(profile.review_interval_days, profile.ease_factor, 5);

        assert!(
            new_interval > 6.0,
            "Interval should increase on quality 5: {}",
            new_interval
        );
        assert!(
            new_ease >= 2.5,
            "Ease should increase on quality 5: {}",
            new_ease
        );

        // Quality 1 (wrong) should reset to 1 day
        let (reset_interval, _) =
            skill_profile::update_spaced_repetition(profile.review_interval_days, profile.ease_factor, 1);
        assert!(
            (reset_interval - 1.0).abs() < 0.01,
            "Interval should reset to 1.0 on failure: {}",
            reset_interval
        );
    }

    #[tokio::test]
    async fn test_get_questions_invalid_topic() {
        let (engine, _question_repo, _skill_repo) = create_engine();
        let user_id = Uuid::new_v4();

        let result = engine
            .get_adaptive_questions(user_id, "trigonometry", 3, 5)
            .await;
        assert!(result.is_err());
        match result.unwrap_err() {
            ApiError::BadRequest(msg) => assert!(msg.contains("Invalid topic")),
            e => panic!("Expected BadRequest, got {:?}", e),
        }
    }

    #[tokio::test]
    async fn test_difficulty_stays_at_max() {
        // Profile already at difficulty 10 with streak
        let profile = SkillProfile {
            id: Uuid::new_v4(),
            user_id: Uuid::new_v4(),
            topic: "addition".to_string(),
            current_difficulty: 10,
            elo_rating: 1500.0,
            recent_accuracy: 95.0,
            last_n_results: vec![true; 10],
            consecutive_correct: 2, // one more triggers level up
            consecutive_wrong: 0,
            next_review_at: Utc::now(),
            review_interval_days: 10.0,
            ease_factor: 2.5,
            total_attempts: 50,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let new_difficulty = skill_profile::calculate_new_difficulty(&profile, true);
        assert_eq!(new_difficulty, 10, "Difficulty should not exceed 10");
    }

    #[tokio::test]
    async fn test_difficulty_stays_at_min() {
        let profile = SkillProfile {
            id: Uuid::new_v4(),
            user_id: Uuid::new_v4(),
            topic: "division".to_string(),
            current_difficulty: 1,
            elo_rating: 800.0,
            recent_accuracy: 20.0,
            last_n_results: vec![false; 5],
            consecutive_correct: 0,
            consecutive_wrong: 1,
            next_review_at: Utc::now(),
            review_interval_days: 1.0,
            ease_factor: 1.3,
            total_attempts: 10,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let new_difficulty = skill_profile::calculate_new_difficulty(&profile, false);
        assert_eq!(new_difficulty, 1, "Difficulty should not go below 1");
    }
}
