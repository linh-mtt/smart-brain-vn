import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_feedback_model.freezed.dart';
part 'session_feedback_model.g.dart';

@freezed
abstract class SessionFeedbackModel with _$SessionFeedbackModel {
  const factory SessionFeedbackModel({
    @JsonKey(name: 'is_correct') required bool isCorrect,
    @JsonKey(name: 'correct_answer') required double correctAnswer,
    @JsonKey(name: 'points_earned') required int pointsEarned,
    @JsonKey(name: 'combo_count') required int comboCount,
    @JsonKey(name: 'combo_multiplier') required double comboMultiplier,
    @JsonKey(name: 'max_combo') required int maxCombo,
    @JsonKey(name: 'new_difficulty') required int newDifficulty,
    @JsonKey(name: 'elo_rating') required double eloRating,
    required int streak,
    @JsonKey(name: 'weak_topics') required List<String> weakTopics,
    @JsonKey(name: 'session_progress')
    required SessionProgressModel sessionProgress,
  }) = _SessionFeedbackModel;

  factory SessionFeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$SessionFeedbackModelFromJson(json);
}

@freezed
abstract class SessionProgressModel with _$SessionProgressModel {
  const factory SessionProgressModel({
    @JsonKey(name: 'total_questions') required int totalQuestions,
    @JsonKey(name: 'correct_count') required int correctCount,
    @JsonKey(name: 'total_points') required int totalPoints,
    @JsonKey(name: 'total_time_ms') required int totalTimeMs,
    required double accuracy,
  }) = _SessionProgressModel;

  factory SessionProgressModel.fromJson(Map<String, dynamic> json) =>
      _$SessionProgressModelFromJson(json);
}
