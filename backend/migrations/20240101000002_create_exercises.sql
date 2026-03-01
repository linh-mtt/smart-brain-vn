-- Create exercise results table
CREATE TABLE IF NOT EXISTS exercise_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(50) NOT NULL,
    difficulty VARCHAR(20) NOT NULL,
    question_text TEXT NOT NULL,
    correct_answer DOUBLE PRECISION NOT NULL,
    user_answer DOUBLE PRECISION,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    points_earned INTEGER NOT NULL DEFAULT 0,
    time_taken_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for exercise queries
CREATE INDEX idx_exercise_results_user_id ON exercise_results (user_id);
CREATE INDEX idx_exercise_results_topic ON exercise_results (topic);
CREATE INDEX idx_exercise_results_user_topic ON exercise_results (user_id, topic);
CREATE INDEX idx_exercise_results_created_at ON exercise_results (created_at);
CREATE INDEX idx_exercise_results_user_created ON exercise_results (user_id, created_at DESC);
