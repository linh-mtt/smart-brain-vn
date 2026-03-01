/// Domain entity representing a recent exercise.
///
/// This is a plain Dart class that represents the core recent exercise
/// concept in the domain layer, independent of data sources.
class RecentExerciseEntity {
  const RecentExerciseEntity({
    required this.id,
    required this.topic,
    required this.difficulty,
    required this.isCorrect,
    required this.pointsEarned,
    required this.createdAt,
  });

  /// Unique exercise identifier.
  final String id;

  /// Topic of the exercise (e.g., "Addition").
  final String topic;

  /// Difficulty level (e.g., "easy", "medium", "hard").
  final String difficulty;

  /// Whether the answer was correct.
  final bool isCorrect;

  /// Points earned for this exercise.
  final int pointsEarned;

  /// Timestamp when the exercise was completed.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentExerciseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'RecentExerciseEntity(id: $id, topic: $topic, correct: $isCorrect)';
}
