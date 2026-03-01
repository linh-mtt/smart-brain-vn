-- Leaderboard entries
CREATE TABLE IF NOT EXISTS leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    period VARCHAR(20) NOT NULL DEFAULT 'all_time',
    total_points INTEGER NOT NULL DEFAULT 0,
    rank INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_leaderboard_entries_user_id ON leaderboard_entries (user_id);
CREATE INDEX idx_leaderboard_entries_period ON leaderboard_entries (period);
CREATE INDEX idx_leaderboard_entries_period_points ON leaderboard_entries (period, total_points DESC);
CREATE INDEX idx_leaderboard_entries_period_rank ON leaderboard_entries (period, rank ASC);
CREATE UNIQUE INDEX idx_leaderboard_entries_user_period ON leaderboard_entries (user_id, period);

-- Auto-update trigger for leaderboard
CREATE TRIGGER trigger_leaderboard_entries_updated_at
    BEFORE UPDATE ON leaderboard_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
