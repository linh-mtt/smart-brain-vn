import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../progress/data/models/topic_progress_model.dart';
import 'child_summary_model.dart';
import 'daily_goal_model.dart';
import 'recent_exercise_model.dart';

part 'child_progress_model.freezed.dart';
part 'child_progress_model.g.dart';

/// Data model for detailed child progress, matching the backend ChildProgress.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class ChildProgressModel with _$ChildProgressModel {
  const factory ChildProgressModel({
    required ChildSummaryModel child,
    @JsonKey(name: 'topic_mastery')
    required List<TopicProgressModel> topicMastery,
    @JsonKey(name: 'daily_goal') DailyGoalModel? dailyGoal,
    @JsonKey(name: 'recent_activity')
    required List<RecentExerciseModel> recentActivity,
  }) = _ChildProgressModel;

  factory ChildProgressModel.fromJson(Map<String, dynamic> json) =>
      _$ChildProgressModelFromJson(json);
}
