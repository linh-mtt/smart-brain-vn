/// Domain entity representing a user's overall progress summary.
///
/// This is a plain Dart class that represents the core progress concept
/// in the domain layer, independent of data sources.
class ProgressSummaryEntity {
  const ProgressSummaryEntity({
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalExercises,
    required this.accuracyRate,
    required this.level,
    required this.xpToNextLevel,
  });

  /// Total points earned by the user.
  final int totalPoints;

  /// Current consecutive days streak.
  final int currentStreak;

  /// Longest streak ever achieved.
  final int longestStreak;

  /// Total number of exercises completed.
  final int totalExercises;

  /// Accuracy rate as a percentage (0.0 - 100.0).
  final double accuracyRate;

  /// Current level of the user.
  final int level;

  /// XP needed to reach the next level.
  final int xpToNextLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressSummaryEntity &&
          runtimeType == other.runtimeType &&
          totalPoints == other.totalPoints &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          totalExercises == other.totalExercises &&
          accuracyRate == other.accuracyRate &&
          level == other.level &&
          xpToNextLevel == other.xpToNextLevel;

  @override
  int get hashCode => Object.hash(
    totalPoints,
    currentStreak,
    longestStreak,
    totalExercises,
    accuracyRate,
    level,
    xpToNextLevel,
  );

  @override
  String toString() =>
      'ProgressSummaryEntity(level: $level, points: $totalPoints, streak: $currentStreak)';
}
