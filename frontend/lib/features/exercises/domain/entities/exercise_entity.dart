/// Domain entity representing a math exercise.
///
/// This is a plain Dart class that represents the core exercise
/// concept in the domain layer, independent of data sources.
class ExerciseEntity {
  const ExerciseEntity({
    required this.id,
    required this.questionText,
    this.options,
    required this.difficulty,
    required this.topic,
  });

  /// Unique exercise identifier.
  final String id;

  /// The question text to display (e.g., "3 + 5 = ?").
  final String questionText;

  /// Multiple-choice options, if available.
  final List<String>? options;

  /// Difficulty level (easy, medium, hard).
  final String difficulty;

  /// Math topic (addition, subtraction, multiplication, division).
  final String topic;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ExerciseEntity(id: $id, question: $questionText, topic: $topic)';
}
