import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/weekly_comparison_entity.dart';

part 'weekly_comparison_model.freezed.dart';
part 'weekly_comparison_model.g.dart';

/// Data model for weekly comparison data, matching the backend response.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class WeeklyComparisonModel with _$WeeklyComparisonModel {
  const factory WeeklyComparisonModel({
    required List<String> days,
    @JsonKey(name: 'this_week') required List<double> thisWeek,
    @JsonKey(name: 'last_week') required List<double> lastWeek,
    @JsonKey(name: 'this_week_average') required double thisWeekAverage,
    @JsonKey(name: 'last_week_average') required double lastWeekAverage,
    @JsonKey(name: 'improvement_percent') required double improvementPercent,
  }) = _WeeklyComparisonModel;

  factory WeeklyComparisonModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyComparisonModelFromJson(json);
}

/// Extension methods for converting between WeeklyComparisonModel and WeeklyComparisonEntity.
extension WeeklyComparisonModelX on WeeklyComparisonModel {
  /// Converts this data model to a domain entity.
  WeeklyComparisonEntity toEntity() {
    return WeeklyComparisonEntity(
      days: days,
      thisWeek: thisWeek,
      lastWeek: lastWeek,
      thisWeekAverage: thisWeekAverage,
      lastWeekAverage: lastWeekAverage,
      improvementPercent: improvementPercent,
    );
  }
}
