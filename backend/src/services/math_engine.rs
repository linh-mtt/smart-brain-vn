use rand::Rng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ─── Enums ───────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MathTopic {
    Addition,
    Subtraction,
    Multiplication,
    Division,
}

impl MathTopic {
    pub fn from_str_value(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "addition" => Some(MathTopic::Addition),
            "subtraction" => Some(MathTopic::Subtraction),
            "multiplication" => Some(MathTopic::Multiplication),
            "division" => Some(MathTopic::Division),
            _ => None,
        }
    }

    pub fn as_str(&self) -> &str {
        match self {
            MathTopic::Addition => "addition",
            MathTopic::Subtraction => "subtraction",
            MathTopic::Multiplication => "multiplication",
            MathTopic::Division => "division",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
}

impl Difficulty {
    pub fn from_str_value(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "easy" => Some(Difficulty::Easy),
            "medium" => Some(Difficulty::Medium),
            "hard" => Some(Difficulty::Hard),
            _ => None,
        }
    }

    pub fn as_str(&self) -> &str {
        match self {
            Difficulty::Easy => "easy",
            Difficulty::Medium => "medium",
            Difficulty::Hard => "hard",
        }
    }
}

// ─── MathProblem ─────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MathProblem {
    pub id: Uuid,
    pub question_text: String,
    pub correct_answer: f64,
    pub options: Option<Vec<String>>,
    pub explanation: String,
    pub topic: String,
    pub difficulty: String,
}

// ─── Problem Generation ──────────────────────────────────────────────────────

pub fn generate_problems(topic: &MathTopic, difficulty: &Difficulty, count: usize) -> Vec<MathProblem> {
    let mut rng = rand::thread_rng();
    (0..count)
        .map(|_| generate_single_problem(&mut rng, topic, difficulty))
        .collect()
}

fn generate_single_problem(
    rng: &mut impl Rng,
    topic: &MathTopic,
    difficulty: &Difficulty,
) -> MathProblem {
    match topic {
        MathTopic::Addition => generate_addition(rng, difficulty),
        MathTopic::Subtraction => generate_subtraction(rng, difficulty),
        MathTopic::Multiplication => generate_multiplication(rng, difficulty),
        MathTopic::Division => generate_division(rng, difficulty),
    }
}

fn generate_addition(rng: &mut impl Rng, difficulty: &Difficulty) -> MathProblem {
    let (a, b) = match difficulty {
        Difficulty::Easy => (rng.gen_range(1..=20), rng.gen_range(1..=20)),
        Difficulty::Medium => (rng.gen_range(10..=100), rng.gen_range(10..=100)),
        Difficulty::Hard => (rng.gen_range(100..=10000), rng.gen_range(100..=10000)),
    };

    let answer = (a + b) as f64;
    let question = format!("{} + {} = ?", a, b);
    let explanation = format!("To add {} and {}, we combine them to get {}.", a, b, a + b);
    let options = generate_options(rng, answer);

    MathProblem {
        id: Uuid::new_v4(),
        question_text: question,
        correct_answer: answer,
        options: Some(options),
        explanation,
        topic: MathTopic::Addition.as_str().to_string(),
        difficulty: difficulty.as_str().to_string(),
    }
}

fn generate_subtraction(rng: &mut impl Rng, difficulty: &Difficulty) -> MathProblem {
    let (a, b) = match difficulty {
        Difficulty::Easy => {
            let b = rng.gen_range(1..=20);
            let a = rng.gen_range(b..=20);
            (a, b)
        }
        Difficulty::Medium => {
            let b = rng.gen_range(10..=100);
            let a = rng.gen_range(b..=100);
            (a, b)
        }
        Difficulty::Hard => {
            let b = rng.gen_range(100..=10000);
            let a = rng.gen_range(b..=10000);
            (a, b)
        }
    };

    let answer = (a - b) as f64;
    let question = format!("{} - {} = ?", a, b);
    let explanation = format!(
        "To subtract {} from {}, we take away {} to get {}.",
        b, a, b, a - b
    );
    let options = generate_options(rng, answer);

    MathProblem {
        id: Uuid::new_v4(),
        question_text: question,
        correct_answer: answer,
        options: Some(options),
        explanation,
        topic: MathTopic::Subtraction.as_str().to_string(),
        difficulty: difficulty.as_str().to_string(),
    }
}

fn generate_multiplication(rng: &mut impl Rng, difficulty: &Difficulty) -> MathProblem {
    let (a, b) = match difficulty {
        Difficulty::Easy => (rng.gen_range(1..=5), rng.gen_range(1..=5)),
        Difficulty::Medium => (rng.gen_range(2..=12), rng.gen_range(2..=12)),
        Difficulty::Hard => (rng.gen_range(10..=999), rng.gen_range(2..=99)),
    };

    let answer = (a * b) as f64;
    let question = format!("{} × {} = ?", a, b);
    let explanation = format!(
        "To multiply {} by {}, we get {} × {} = {}.",
        a, b, a, b, a * b
    );
    let options = generate_options(rng, answer);

    MathProblem {
        id: Uuid::new_v4(),
        question_text: question,
        correct_answer: answer,
        options: Some(options),
        explanation,
        topic: MathTopic::Multiplication.as_str().to_string(),
        difficulty: difficulty.as_str().to_string(),
    }
}

fn generate_division(rng: &mut impl Rng, difficulty: &Difficulty) -> MathProblem {
    match difficulty {
        Difficulty::Easy => {
            let divisor = rng.gen_range(1..=5);
            let result = rng.gen_range(1..=10);
            let dividend = divisor * result;
            let answer = result as f64;
            let question = format!("{} ÷ {} = ?", dividend, divisor);
            let explanation = format!(
                "{} divided by {} equals {} because {} × {} = {}.",
                dividend, divisor, result, divisor, result, dividend
            );
            let options = generate_options(rng, answer);
            MathProblem {
                id: Uuid::new_v4(),
                question_text: question,
                correct_answer: answer,
                options: Some(options),
                explanation,
                topic: MathTopic::Division.as_str().to_string(),
                difficulty: Difficulty::Easy.as_str().to_string(),
            }
        }
        Difficulty::Medium => {
            let divisor = rng.gen_range(2..=12);
            let result = rng.gen_range(2..=12);
            let dividend = divisor * result;
            let answer = result as f64;
            let question = format!("{} ÷ {} = ?", dividend, divisor);
            let explanation = format!(
                "{} divided by {} equals {} because {} × {} = {}.",
                dividend, divisor, result, divisor, result, dividend
            );
            let options = generate_options(rng, answer);
            MathProblem {
                id: Uuid::new_v4(),
                question_text: question,
                correct_answer: answer,
                options: Some(options),
                explanation,
                topic: MathTopic::Division.as_str().to_string(),
                difficulty: Difficulty::Medium.as_str().to_string(),
            }
        }
        Difficulty::Hard => {
            let divisor = rng.gen_range(2..=20);
            let dividend = rng.gen_range(10..=500);
            let quotient = dividend / divisor;
            let remainder = dividend % divisor;
            let answer = if remainder == 0 {
                quotient as f64
            } else {
                ((dividend as f64 / divisor as f64) * 100.0).round() / 100.0
            };
            let question = if remainder == 0 {
                format!("{} ÷ {} = ?", dividend, divisor)
            } else {
                format!(
                    "{} ÷ {} = ? (round to 2 decimal places)",
                    dividend, divisor
                )
            };
            let explanation = if remainder == 0 {
                format!(
                    "{} divided by {} equals {} exactly.",
                    dividend, divisor, quotient
                )
            } else {
                format!(
                    "{} divided by {} equals approximately {:.2}. The quotient is {} with remainder {}.",
                    dividend, divisor, answer, quotient, remainder
                )
            };
            let options = generate_options(rng, answer);
            MathProblem {
                id: Uuid::new_v4(),
                question_text: question,
                correct_answer: answer,
                options: Some(options),
                explanation,
                topic: MathTopic::Division.as_str().to_string(),
                difficulty: Difficulty::Hard.as_str().to_string(),
            }
        }
    }
}

fn generate_options(rng: &mut impl Rng, correct: f64) -> Vec<String> {
    let mut options: Vec<f64> = vec![correct];
    let range_offset = if correct.abs() < 10.0 { 5.0 } else { correct.abs() * 0.3 };

    while options.len() < 4 {
        let wrong = if correct == correct.floor() {
            let offset = rng.gen_range(1..=(range_offset.max(3.0) as i64));
            let sign = if rng.gen_bool(0.5) { 1 } else { -1 };
            let candidate = correct + (offset * sign) as f64;
            if candidate < 0.0 && correct >= 0.0 {
                correct + offset as f64
            } else {
                candidate
            }
        } else {
            let offset = rng.gen_range(1..=30) as f64 / 100.0 * range_offset;
            let sign: f64 = if rng.gen_bool(0.5) { 1.0 } else { -1.0 };
            ((correct + offset * sign) * 100.0).round() / 100.0
        };

        if !options.iter().any(|o| (o - wrong).abs() < 0.001) {
            options.push(wrong);
        }
    }

    // Shuffle options
    for i in (1..options.len()).rev() {
        let j = rng.gen_range(0..=i);
        options.swap(i, j);
    }

    options
        .iter()
        .map(|v| {
            if *v == v.floor() {
                format!("{}", *v as i64)
            } else {
                format!("{:.2}", v)
            }
        })
        .collect()
}
