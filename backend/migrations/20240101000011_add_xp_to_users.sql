-- Add XP and level tracking columns to users table
ALTER TABLE users ADD COLUMN total_xp BIGINT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN current_level INTEGER NOT NULL DEFAULT 1;

-- Index for leaderboard queries by XP
CREATE INDEX idx_users_total_xp ON users (total_xp DESC);
CREATE INDEX idx_users_current_level ON users (current_level);
