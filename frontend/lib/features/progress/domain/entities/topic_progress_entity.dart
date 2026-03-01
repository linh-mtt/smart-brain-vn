/// Domain entity representing a user's progress in a specific topic.
///
/// This is a plain Dart class that represents the topic progress concept
/// in the domain layer, independent of data sources.
class TopicProgressEntity {
  const TopicProgressEntity({
    required this.topic,
    required this.masteryScore,
    required this.totalAnswered,
    required this.correctCount,
    required this.recentScores,
  });

  /// The topic name (e.g., 'addition', 'subtraction').
  final String topic;

  /// Mastery score as a percentage (0.0 - 100.0).
  final double masteryScore;

  /// Total number of questions answered in this topic.
  final int totalAnswered;

  /// Number of correctly answered questions.
  final int correctCount;

  /// Recent answer results (true = correct, false = incorrect).
  final List<bool> recentScores;

  /// Accuracy rate for this topic.
  double get accuracyRate =>
      totalAnswered > 0 ? (correctCount / totalAnswered) * 100 : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicProgressEntity &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          masteryScore == other.masteryScore &&
          totalAnswered == other.totalAnswered &&
          correctCount == other.correctCount;

  @override
  int get hashCode =>
      Object.hash(topic, masteryScore, totalAnswered, correctCount);

  @override
  String toString() =>
      'TopicProgressEntity(topic: $topic, mastery: $masteryScore%)';
}
