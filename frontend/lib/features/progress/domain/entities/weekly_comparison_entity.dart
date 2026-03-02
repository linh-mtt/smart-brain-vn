/// Domain entity representing weekly comparison data for bar chart visualization.
///
/// Compares this week's performance against last week.
class WeeklyComparisonEntity {
  const WeeklyComparisonEntity({
    required this.days,
    required this.thisWeek,
    required this.lastWeek,
    required this.thisWeekAverage,
    required this.lastWeekAverage,
    required this.improvementPercent,
  });

  /// Day labels (e.g., ['Mon', 'Tue', ...]).
  final List<String> days;

  /// Scores for each day this week.
  final List<double> thisWeek;

  /// Scores for each day last week.
  final List<double> lastWeek;

  /// Average score this week.
  final double thisWeekAverage;

  /// Average score last week.
  final double lastWeekAverage;

  /// Improvement percentage from last week to this week.
  final double improvementPercent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyComparisonEntity &&
          runtimeType == other.runtimeType &&
          thisWeekAverage == other.thisWeekAverage &&
          lastWeekAverage == other.lastWeekAverage &&
          improvementPercent == other.improvementPercent;

  @override
  int get hashCode =>
      Object.hash(thisWeekAverage, lastWeekAverage, improvementPercent);

  @override
  String toString() =>
      'WeeklyComparisonEntity(thisWeekAvg: $thisWeekAverage, lastWeekAvg: $lastWeekAverage, improvement: $improvementPercent%)';
}
