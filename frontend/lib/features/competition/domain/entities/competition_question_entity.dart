/// Represents a question in a competition match.
class CompetitionQuestionEntity {
  const CompetitionQuestionEntity({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.difficultyLevel,
    required this.topic,
  });

  final String id;
  final String questionText;
  final double correctAnswer;
  final List<String> options;
  final int difficultyLevel;
  final String topic;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompetitionQuestionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
