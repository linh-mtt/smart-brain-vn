/// A quiz question used to test understanding of a learning tip.
class QuizQuestionEntity {
  const QuizQuestionEntity({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Unique identifier for this question.
  final String id;

  /// The question text.
  final String question;

  /// List of 4 answer options.
  final List<String> options;

  /// Index of the correct answer in [options].
  final int correctIndex;

  /// Explanation of why the answer is correct.
  final String explanation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizQuestionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
