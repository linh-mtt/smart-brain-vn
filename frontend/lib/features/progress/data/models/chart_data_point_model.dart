import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/chart_data_point_entity.dart';

part 'chart_data_point_model.freezed.dart';
part 'chart_data_point_model.g.dart';

/// Data model for a chart data point, matching the backend response.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class ChartDataPointModel with _$ChartDataPointModel {
  const factory ChartDataPointModel({
    required String date,
    required double value,
  }) = _ChartDataPointModel;

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) =>
      _$ChartDataPointModelFromJson(json);
}

/// Extension methods for converting between ChartDataPointModel and ChartDataPointEntity.
extension ChartDataPointModelX on ChartDataPointModel {
  /// Converts this data model to a domain entity.
  ChartDataPointEntity toEntity() {
    return ChartDataPointEntity(date: DateTime.parse(date), value: value);
  }
}
