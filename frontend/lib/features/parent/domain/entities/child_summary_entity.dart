/// Domain entity representing a child's summary information.
///
/// This is a plain Dart class that represents the core child summary
/// concept in the domain layer, independent of data sources.
class ChildSummaryEntity {
  const ChildSummaryEntity({
    required this.childId,
    required this.username,
    this.displayName,
    required this.gradeLevel,
    required this.totalPoints,
    required this.totalExercises,
    required this.currentStreak,
  });

  /// Unique child identifier.
  final String childId;

  /// Child's username.
  final String username;

  /// Child's display name.
  final String? displayName;

  /// Child's current grade level.
  final int gradeLevel;

  /// Total points accumulated.
  final int totalPoints;

  /// Total exercises completed.
  final int totalExercises;

  /// Current daily streak.
  final int currentStreak;

  /// Returns the display name, falling back to username.
  String get effectiveDisplayName => displayName ?? username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildSummaryEntity &&
          runtimeType == other.runtimeType &&
          childId == other.childId;

  @override
  int get hashCode => childId.hashCode;

  @override
  String toString() =>
      'ChildSummaryEntity(childId: $childId, username: $username)';
}
