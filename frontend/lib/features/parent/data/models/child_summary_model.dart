import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/child_summary_entity.dart';

part 'child_summary_model.freezed.dart';
part 'child_summary_model.g.dart';

/// Data model for a child summary, matching the backend ChildSummary.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class ChildSummaryModel with _$ChildSummaryModel {
  const factory ChildSummaryModel({
    @JsonKey(name: 'child_id') required String childId,
    required String username,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'grade_level') required int gradeLevel,
    @JsonKey(name: 'total_points') required int totalPoints,
    @JsonKey(name: 'total_exercises') required int totalExercises,
    @JsonKey(name: 'current_streak') required int currentStreak,
  }) = _ChildSummaryModel;

  factory ChildSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$ChildSummaryModelFromJson(json);
}

/// Extension methods for converting between ChildSummaryModel and ChildSummaryEntity.
extension ChildSummaryModelX on ChildSummaryModel {
  /// Converts this data model to a domain entity.
  ChildSummaryEntity toEntity() {
    return ChildSummaryEntity(
      childId: childId,
      username: username,
      displayName: displayName,
      gradeLevel: gradeLevel,
      totalPoints: totalPoints,
      totalExercises: totalExercises,
      currentStreak: currentStreak,
    );
  }
}
