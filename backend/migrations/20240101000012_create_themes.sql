-- Unlockable themes definition table
CREATE TABLE IF NOT EXISTS unlockable_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    emoji VARCHAR(10) NOT NULL DEFAULT '🎨',
    required_level INTEGER NOT NULL DEFAULT 1,
    required_xp BIGINT NOT NULL DEFAULT 0,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User-unlocked themes (many-to-many)
CREATE TABLE IF NOT EXISTS user_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    theme_id UUID NOT NULL REFERENCES unlockable_themes(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (user_id, theme_id)
);

-- Indexes
CREATE INDEX idx_user_themes_user_id ON user_themes (user_id);
CREATE INDEX idx_user_themes_active ON user_themes (user_id, is_active) WHERE is_active = TRUE;

-- Seed default themes
INSERT INTO unlockable_themes (name, description, emoji, required_level, required_xp, is_premium) VALUES
    ('ocean_blue', 'Cool ocean vibes with calming blue tones', '🌊', 1, 0, FALSE),
    ('forest_green', 'Natural forest theme with earthy greens', '🌲', 3, 200, FALSE),
    ('sunset_orange', 'Warm sunset gradient with vibrant oranges', '🌅', 5, 500, FALSE),
    ('galaxy_purple', 'Deep space theme with cosmic purples', '🌌', 8, 1000, FALSE),
    ('candy_pink', 'Sweet candy theme with playful pinks', '🍬', 10, 1500, FALSE),
    ('golden_star', 'Premium golden theme for champions', '⭐', 15, 3000, FALSE),
    ('rainbow_burst', 'Colorful rainbow explosion theme', '🌈', 20, 5000, FALSE),
    ('diamond_ice', 'Premium crystal clear diamond theme', '💎', 25, 8000, TRUE),
    ('dragon_fire', 'Legendary dragon fire theme', '🐉', 30, 12000, TRUE);
