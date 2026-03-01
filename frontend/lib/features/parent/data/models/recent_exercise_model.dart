import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_exercise_model.freezed.dart';
part 'recent_exercise_model.g.dart';

/// Data model for a recent exercise entry, matching the backend RecentExercise.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class RecentExerciseModel with _$RecentExerciseModel {
  const factory RecentExerciseModel({
    required String id,
    required String topic,
    required String difficulty,
    @JsonKey(name: 'is_correct') required bool isCorrect,
    @JsonKey(name: 'points_earned') required int pointsEarned,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _RecentExerciseModel;

  factory RecentExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$RecentExerciseModelFromJson(json);
}
