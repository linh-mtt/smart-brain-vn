/// Domain entity representing feedback for a submitted answer.
///
/// Contains information about whether the answer was correct,
/// the actual correct answer, points earned, and an explanation.
class AnswerFeedbackEntity {
  const AnswerFeedbackEntity({
    required this.isCorrect,
    required this.correctAnswer,
    required this.pointsEarned,
    required this.explanation,
  });

  /// Whether the submitted answer was correct.
  final bool isCorrect;

  /// The correct answer value.
  final double correctAnswer;

  /// Points earned for this answer.
  final int pointsEarned;

  /// Explanation of the solution.
  final String explanation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerFeedbackEntity &&
          runtimeType == other.runtimeType &&
          isCorrect == other.isCorrect &&
          correctAnswer == other.correctAnswer &&
          pointsEarned == other.pointsEarned;

  @override
  int get hashCode => Object.hash(isCorrect, correctAnswer, pointsEarned);

  @override
  String toString() =>
      'AnswerFeedbackEntity(isCorrect: $isCorrect, correctAnswer: $correctAnswer, points: $pointsEarned)';
}
