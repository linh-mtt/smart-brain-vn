-- Skill profiles: per-user, per-topic adaptive difficulty state
CREATE TABLE IF NOT EXISTS skill_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(50) NOT NULL,
    current_difficulty INTEGER NOT NULL DEFAULT 1 CHECK (current_difficulty BETWEEN 1 AND 10),
    elo_rating DOUBLE PRECISION NOT NULL DEFAULT 1000.0,
    recent_accuracy DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    last_n_results JSONB NOT NULL DEFAULT '[]'::jsonb,
    consecutive_correct INTEGER NOT NULL DEFAULT 0,
    consecutive_wrong INTEGER NOT NULL DEFAULT 0,
    next_review_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    review_interval_days DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    total_attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, topic)
);

CREATE INDEX idx_skill_profiles_user ON skill_profiles (user_id);
CREATE INDEX idx_skill_profiles_user_topic ON skill_profiles (user_id, topic);
CREATE INDEX idx_skill_profiles_review ON skill_profiles (user_id, next_review_at);

CREATE TRIGGER trigger_skill_profiles_updated_at
    BEFORE UPDATE ON skill_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
