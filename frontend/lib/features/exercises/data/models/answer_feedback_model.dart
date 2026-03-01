import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer_feedback_model.freezed.dart';
part 'answer_feedback_model.g.dart';

/// Data model for answer feedback, matching the backend AnswerFeedback.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class AnswerFeedbackModel with _$AnswerFeedbackModel {
  const factory AnswerFeedbackModel({
    @JsonKey(name: 'is_correct') required bool isCorrect,
    @JsonKey(name: 'correct_answer') required double correctAnswer,
    @JsonKey(name: 'points_earned') required int pointsEarned,
    required String explanation,
  }) = _AnswerFeedbackModel;

  factory AnswerFeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerFeedbackModelFromJson(json);
}
