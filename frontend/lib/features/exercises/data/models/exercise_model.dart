import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

/// Data model for exercise, matching the backend ExerciseResponse.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String id,
    @JsonKey(name: 'question_text') required String questionText,
    List<String>? options,
    required String difficulty,
    required String topic,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);
}
