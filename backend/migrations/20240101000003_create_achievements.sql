-- Create achievements definition table
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    emoji VARCHAR(10) NOT NULL DEFAULT '🏆',
    reward_points INTEGER NOT NULL DEFAULT 0,
    criteria_type VARCHAR(50) NOT NULL,
    criteria_value INTEGER NOT NULL DEFAULT 0
);

-- Create user achievements (unlocked achievements)
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, achievement_id)
);

-- Indexes
CREATE INDEX idx_user_achievements_user_id ON user_achievements (user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements (achievement_id);

-- Seed achievements data
INSERT INTO achievements (name, description, emoji, reward_points, criteria_type, criteria_value) VALUES
    ('first_step', 'Answer your first question', '🎯', 10, 'total_answered', 1),
    ('ten_streak', 'Get 10 correct answers in a row', '🔥', 50, 'streak', 10),
    ('hundred_correct', 'Answer 100 questions correctly', '💯', 100, 'total_correct', 100),
    ('addition_master', '90% accuracy in addition (min 50 questions)', '➕', 200, 'addition_mastery', 90),
    ('subtraction_master', '90% accuracy in subtraction (min 50 questions)', '➖', 200, 'subtraction_mastery', 90),
    ('multiplication_master', '90% accuracy in multiplication (min 50 questions)', '✖️', 200, 'multiplication_mastery', 90),
    ('division_master', '90% accuracy in division (min 50 questions)', '➗', 200, 'division_mastery', 90),
    ('speed_demon', 'Answer 5 questions in under 30 seconds total', '⚡', 75, 'speed', 30000),
    ('perfect_day', '100% accuracy in a session (min 10 questions)', '⭐', 150, 'perfect_session', 10),
    ('week_warrior', 'Practice 7 days in a row', '🗓️', 100, 'day_streak', 7),
    ('month_champion', 'Practice 30 days in a row', '👑', 500, 'day_streak', 30),
    ('level_5', 'Reach level 5', '🌟', 50, 'level', 5),
    ('level_10', 'Reach level 10', '🌠', 100, 'level', 10),
    ('level_20', 'Reach level 20', '💫', 250, 'level', 20),
    ('thousand_points', 'Earn 1000 total points', '🏅', 100, 'total_points', 1000);
