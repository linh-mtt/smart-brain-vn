-- Question bank: pre-defined question templates with granular difficulty levels (1-10)
CREATE TABLE IF NOT EXISTS question_bank (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic VARCHAR(50) NOT NULL,
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 10),
    question_template TEXT NOT NULL,
    operand_min INTEGER NOT NULL,
    operand_max INTEGER NOT NULL,
    explanation_template TEXT NOT NULL,
    grade_min INTEGER NOT NULL DEFAULT 1 CHECK (grade_min BETWEEN 1 AND 6),
    grade_max INTEGER NOT NULL DEFAULT 6 CHECK (grade_max BETWEEN 1 AND 6),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_question_bank_topic ON question_bank (topic);
CREATE INDEX idx_question_bank_difficulty ON question_bank (difficulty_level);
CREATE INDEX idx_question_bank_topic_difficulty ON question_bank (topic, difficulty_level);
CREATE INDEX idx_question_bank_active ON question_bank (active) WHERE active = true;

-- ─── Seed Data: Addition ─────────────────────────────────────────────────────
INSERT INTO question_bank (topic, difficulty_level, question_template, operand_min, operand_max, explanation_template, grade_min, grade_max) VALUES
('addition', 1, '{a} + {b} = ?', 1, 10, 'To add {a} and {b}, combine them to get {answer}.', 1, 2),
('addition', 2, '{a} + {b} = ?', 1, 20, 'To add {a} and {b}, combine them to get {answer}.', 1, 2),
('addition', 3, '{a} + {b} = ?', 10, 50, '{a} + {b} = {answer}. Try adding the tens first, then the ones.', 1, 3),
('addition', 4, '{a} + {b} = ?', 10, 100, '{a} + {b} = {answer}. Break it into smaller parts if needed.', 2, 4),
('addition', 5, '{a} + {b} = ?', 50, 500, '{a} + {b} = {answer}. Line up the digits by place value.', 2, 4),
('addition', 6, '{a} + {b} = ?', 100, 1000, '{a} + {b} = {answer}. Remember to carry when digits sum to 10 or more.', 3, 5),
('addition', 7, '{a} + {b} = ?', 100, 5000, '{a} + {b} = {answer}. Add column by column from right to left.', 3, 5),
('addition', 8, '{a} + {b} = ?', 500, 10000, '{a} + {b} = {answer}. Work carefully with large numbers.', 4, 6),
('addition', 9, '{a} + {b} = ?', 1000, 50000, '{a} + {b} = {answer}. Use estimation to check your answer.', 5, 6),
('addition', 10, '{a} + {b} = ?', 5000, 99999, '{a} + {b} = {answer}. Great job working with large numbers!', 5, 6),

-- ─── Seed Data: Subtraction ──────────────────────────────────────────────────
('subtraction', 1, '{a} - {b} = ?', 1, 10, 'To subtract {b} from {a}, take away {b} to get {answer}.', 1, 2),
('subtraction', 2, '{a} - {b} = ?', 1, 20, '{a} - {b} = {answer}. Count back from {a} by {b}.', 1, 2),
('subtraction', 3, '{a} - {b} = ?', 10, 50, '{a} - {b} = {answer}. Subtract the ones, then the tens.', 1, 3),
('subtraction', 4, '{a} - {b} = ?', 10, 100, '{a} - {b} = {answer}. You may need to borrow from the tens place.', 2, 4),
('subtraction', 5, '{a} - {b} = ?', 50, 500, '{a} - {b} = {answer}. Line up place values carefully.', 2, 4),
('subtraction', 6, '{a} - {b} = ?', 100, 1000, '{a} - {b} = {answer}. Borrow when the top digit is smaller.', 3, 5),
('subtraction', 7, '{a} - {b} = ?', 100, 5000, '{a} - {b} = {answer}. Work column by column from right to left.', 3, 5),
('subtraction', 8, '{a} - {b} = ?', 500, 10000, '{a} - {b} = {answer}. Check by adding {answer} + {b}.', 4, 6),
('subtraction', 9, '{a} - {b} = ?', 1000, 50000, '{a} - {b} = {answer}. Use estimation to verify.', 5, 6),
('subtraction', 10, '{a} - {b} = ?', 5000, 99999, '{a} - {b} = {answer}. Excellent work with large subtraction!', 5, 6),

-- ─── Seed Data: Multiplication ───────────────────────────────────────────────
('multiplication', 1, '{a} × {b} = ?', 1, 3, '{a} × {b} means {a} groups of {b}, which equals {answer}.', 1, 2),
('multiplication', 2, '{a} × {b} = ?', 1, 5, '{a} × {b} = {answer}. Think of it as repeated addition.', 1, 3),
('multiplication', 3, '{a} × {b} = ?', 2, 8, '{a} × {b} = {answer}. Use your times tables!', 2, 3),
('multiplication', 4, '{a} × {b} = ?', 2, 12, '{a} × {b} = {answer}. Practice your multiplication facts.', 2, 4),
('multiplication', 5, '{a} × {b} = ?', 5, 20, '{a} × {b} = {answer}. Break larger numbers into parts.', 3, 4),
('multiplication', 6, '{a} × {b} = ?', 10, 50, '{a} × {b} = {answer}. Multiply each digit and add partial products.', 3, 5),
('multiplication', 7, '{a} × {b} = ?', 10, 99, '{a} × {b} = {answer}. Use the standard algorithm.', 4, 5),
('multiplication', 8, '{a} × {b} = ?', 20, 200, '{a} × {b} = {answer}. Multiply step by step.', 4, 6),
('multiplication', 9, '{a} × {b} = ?', 50, 500, '{a} × {b} = {answer}. Keep track of place values.', 5, 6),
('multiplication', 10, '{a} × {b} = ?', 100, 999, '{a} × {b} = {answer}. Outstanding multiplication skills!', 5, 6),

-- ─── Seed Data: Division ─────────────────────────────────────────────────────
('division', 1, '{a} ÷ {b} = ?', 1, 5, '{a} divided by {b} equals {answer} because {b} × {answer} = {a}.', 1, 2),
('division', 2, '{a} ÷ {b} = ?', 1, 10, '{a} ÷ {b} = {answer}. Think: what times {b} equals {a}?', 2, 3),
('division', 3, '{a} ÷ {b} = ?', 2, 12, '{a} ÷ {b} = {answer}. Use your division facts.', 2, 3),
('division', 4, '{a} ÷ {b} = ?', 2, 15, '{a} ÷ {b} = {answer}. Division is the opposite of multiplication.', 2, 4),
('division', 5, '{a} ÷ {b} = ?', 5, 25, '{a} ÷ {b} = {answer}. Try to find equal groups.', 3, 4),
('division', 6, '{a} ÷ {b} = ?', 5, 50, '{a} ÷ {b} = {answer}. Use long division if needed.', 3, 5),
('division', 7, '{a} ÷ {b} = ?', 10, 100, '{a} ÷ {b} = {answer}. Divide step by step.', 4, 5),
('division', 8, '{a} ÷ {b} = ?', 10, 200, '{a} ÷ {b} = {answer}. Check by multiplying back.', 4, 6),
('division', 9, '{a} ÷ {b} = ?', 20, 500, '{a} ÷ {b} = {answer}. Estimate first, then calculate.', 5, 6),
('division', 10, '{a} ÷ {b} = ?', 50, 999, '{a} ÷ {b} = {answer}. Impressive division skills!', 5, 6);
