import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_goal_model.freezed.dart';
part 'daily_goal_model.g.dart';

/// Data model for daily learning goals, matching the backend DailyGoalResponse.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class DailyGoalModel with _$DailyGoalModel {
  const factory DailyGoalModel({
    @JsonKey(name: 'daily_exercise_target') required int dailyExerciseTarget,
    @JsonKey(name: 'daily_time_target_minutes')
    required int dailyTimeTargetMinutes,
    @JsonKey(name: 'active_topics') required List<dynamic> activeTopics,
  }) = _DailyGoalModel;

  factory DailyGoalModel.fromJson(Map<String, dynamic> json) =>
      _$DailyGoalModelFromJson(json);
}
