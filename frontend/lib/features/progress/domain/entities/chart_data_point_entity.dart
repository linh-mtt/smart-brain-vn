/// Domain entity representing a single data point for chart visualization.
///
/// Used for both accuracy history and speed history charts.
class ChartDataPointEntity {
  const ChartDataPointEntity({required this.date, required this.value});

  /// The date of this data point.
  final DateTime date;

  /// The value at this date (accuracy %, speed in seconds, etc.).
  final double value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartDataPointEntity &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          value == other.value;

  @override
  int get hashCode => Object.hash(date, value);

  @override
  String toString() => 'ChartDataPointEntity(date: $date, value: $value)';
}
