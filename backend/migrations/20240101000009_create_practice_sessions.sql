-- Practice sessions: tracks a timed sequence of adaptive questions
CREATE TYPE session_status AS ENUM ('active', 'completed', 'abandoned');

CREATE TABLE IF NOT EXISTS practice_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(50) NOT NULL,
    status session_status NOT NULL DEFAULT 'active',
    total_questions INTEGER NOT NULL DEFAULT 0,
    correct_count INTEGER NOT NULL DEFAULT 0,
    total_points INTEGER NOT NULL DEFAULT 0,
    total_time_ms BIGINT NOT NULL DEFAULT 0,
    max_combo INTEGER NOT NULL DEFAULT 0,
    current_combo INTEGER NOT NULL DEFAULT 0,
    difficulty_start INTEGER NOT NULL DEFAULT 1 CHECK (difficulty_start BETWEEN 1 AND 10),
    difficulty_end INTEGER NOT NULL DEFAULT 1 CHECK (difficulty_end BETWEEN 1 AND 10),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for session queries
CREATE INDEX idx_practice_sessions_user ON practice_sessions (user_id);
CREATE INDEX idx_practice_sessions_user_status ON practice_sessions (user_id, status);
CREATE INDEX idx_practice_sessions_user_topic ON practice_sessions (user_id, topic);
CREATE INDEX idx_practice_sessions_started ON practice_sessions (started_at DESC);

CREATE TRIGGER trigger_practice_sessions_updated_at
    BEFORE UPDATE ON practice_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
