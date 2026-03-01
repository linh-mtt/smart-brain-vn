-- Practice results: individual answer records within a session
CREATE TABLE IF NOT EXISTS practice_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES practice_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id UUID NOT NULL,
    topic VARCHAR(50) NOT NULL,
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 10),
    question_text TEXT NOT NULL,
    correct_answer DOUBLE PRECISION NOT NULL,
    user_answer DOUBLE PRECISION NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    points_earned INTEGER NOT NULL DEFAULT 0,
    combo_multiplier DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    combo_count INTEGER NOT NULL DEFAULT 0,
    time_taken_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for result queries
CREATE INDEX idx_practice_results_session ON practice_results (session_id);
CREATE INDEX idx_practice_results_user ON practice_results (user_id);
CREATE INDEX idx_practice_results_session_created ON practice_results (session_id, created_at);
CREATE INDEX idx_practice_results_user_topic ON practice_results (user_id, topic);
