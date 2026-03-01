class PracticeQuestionEntity {
  const PracticeQuestionEntity({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.explanation,
    required this.topic,
    required this.difficultyLevel,
  });

  final String id;
  final String questionText;
  final double correctAnswer;
  final List<String> options;
  final String explanation;
  final String topic;
  final int difficultyLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeQuestionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
