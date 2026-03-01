/// Domain entity representing daily learning goals.
///
/// This is a plain Dart class that represents the core daily goal
/// concept in the domain layer, independent of data sources.
class DailyGoalEntity {
  const DailyGoalEntity({
    required this.dailyExerciseTarget,
    required this.dailyTimeTargetMinutes,
    required this.activeTopics,
  });

  /// Target number of exercises per day.
  final int dailyExerciseTarget;

  /// Target time in minutes per day.
  final int dailyTimeTargetMinutes;

  /// List of active topics for the child.
  final List<dynamic> activeTopics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGoalEntity &&
          runtimeType == other.runtimeType &&
          dailyExerciseTarget == other.dailyExerciseTarget &&
          dailyTimeTargetMinutes == other.dailyTimeTargetMinutes;

  @override
  int get hashCode => Object.hash(dailyExerciseTarget, dailyTimeTargetMinutes);

  @override
  String toString() =>
      'DailyGoalEntity(exercises: $dailyExerciseTarget, minutes: $dailyTimeTargetMinutes)';
}
