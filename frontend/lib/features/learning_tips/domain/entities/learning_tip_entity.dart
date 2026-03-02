import 'quiz_question_entity.dart';
import 'tip_step_entity.dart';

/// A learning tip that teaches a math shortcut or strategy.
///
/// Contains tutorial steps for learning and quiz questions for practice.
class LearningTipEntity {
  const LearningTipEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.difficulty,
    required this.steps,
    required this.quizQuestions,
    required this.animationAsset,
    required this.color,
  });

  /// Unique identifier for this tip.
  final String id;

  /// Short title (e.g., "Adding 9 Trick").
  final String title;

  /// Brief description of the strategy.
  final String description;

  /// Category key (e.g., 'addition', 'multiplication', 'mental_math').
  final String category;

  /// Emoji icon for display (e.g., '➕', '✖️', '🧠').
  final String icon;

  /// Difficulty level: 1 (easy), 2 (medium), 3 (hard).
  final int difficulty;

  /// Ordered tutorial steps explaining the strategy.
  final List<TipStepEntity> steps;

  /// Quiz questions to test understanding.
  final List<QuizQuestionEntity> quizQuestions;

  /// Lottie animation asset path.
  final String animationAsset;

  /// Hex color string for theming (e.g., '#FF6B6B').
  final String color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningTipEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
