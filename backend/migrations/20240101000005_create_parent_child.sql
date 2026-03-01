-- Parent-child relationship links
CREATE TABLE IF NOT EXISTS parent_child_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (parent_id, child_id)
);

-- Daily goals set by parents for children
CREATE TABLE IF NOT EXISTS daily_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    daily_exercise_target INTEGER NOT NULL DEFAULT 10,
    daily_time_target_minutes INTEGER NOT NULL DEFAULT 15,
    active_topics JSONB NOT NULL DEFAULT '["addition", "subtraction"]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (parent_id, child_id)
);

-- Indexes
CREATE INDEX idx_parent_child_links_parent_id ON parent_child_links (parent_id);
CREATE INDEX idx_parent_child_links_child_id ON parent_child_links (child_id);
CREATE INDEX idx_daily_goals_parent_id ON daily_goals (parent_id);
CREATE INDEX idx_daily_goals_child_id ON daily_goals (child_id);

-- Auto-update trigger for daily_goals
CREATE TRIGGER trigger_daily_goals_updated_at
    BEFORE UPDATE ON daily_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
