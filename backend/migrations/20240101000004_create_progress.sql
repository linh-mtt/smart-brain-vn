-- Daily progress tracking
CREATE TABLE IF NOT EXISTS daily_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_exercises INTEGER NOT NULL DEFAULT 0,
    correct_count INTEGER NOT NULL DEFAULT 0,
    total_points INTEGER NOT NULL DEFAULT 0,
    total_time_ms BIGINT NOT NULL DEFAULT 0,
    streak_count INTEGER NOT NULL DEFAULT 0,
    UNIQUE (user_id, date)
);

-- Topic mastery tracking
CREATE TABLE IF NOT EXISTS topic_mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(50) NOT NULL,
    total_answered INTEGER NOT NULL DEFAULT 0,
    correct_count INTEGER NOT NULL DEFAULT 0,
    mastery_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    last_practiced TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, topic)
);

-- Indexes
CREATE INDEX idx_daily_progress_user_id ON daily_progress (user_id);
CREATE INDEX idx_daily_progress_date ON daily_progress (date);
CREATE INDEX idx_daily_progress_user_date ON daily_progress (user_id, date DESC);
CREATE INDEX idx_topic_mastery_user_id ON topic_mastery (user_id);
CREATE INDEX idx_topic_mastery_topic ON topic_mastery (topic);
CREATE INDEX idx_topic_mastery_user_topic ON topic_mastery (user_id, topic);

-- Auto-update trigger for topic_mastery
CREATE TRIGGER trigger_topic_mastery_updated_at
    BEFORE UPDATE ON topic_mastery
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
