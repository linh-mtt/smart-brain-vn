import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/progress_summary_entity.dart';

part 'progress_summary_model.freezed.dart';
part 'progress_summary_model.g.dart';

/// Data model for progress summary, matching the backend ProgressSummary.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class ProgressSummaryModel with _$ProgressSummaryModel {
  const factory ProgressSummaryModel({
    @JsonKey(name: 'total_points') required int totalPoints,
    @JsonKey(name: 'current_streak') required int currentStreak,
    @JsonKey(name: 'longest_streak') required int longestStreak,
    @JsonKey(name: 'total_exercises') required int totalExercises,
    @JsonKey(name: 'accuracy_rate') required double accuracyRate,
    required int level,
    @JsonKey(name: 'xp_to_next_level') required int xpToNextLevel,
  }) = _ProgressSummaryModel;

  factory ProgressSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressSummaryModelFromJson(json);
}

/// Extension methods for converting between ProgressSummaryModel and ProgressSummaryEntity.
extension ProgressSummaryModelX on ProgressSummaryModel {
  /// Converts this data model to a domain entity.
  ProgressSummaryEntity toEntity() {
    return ProgressSummaryEntity(
      totalPoints: totalPoints,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalExercises: totalExercises,
      accuracyRate: accuracyRate,
      level: level,
      xpToNextLevel: xpToNextLevel,
    );
  }
}
