import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_result_model.freezed.dart';
part 'session_result_model.g.dart';

@freezed
abstract class SessionResultModel with _$SessionResultModel {
  const factory SessionResultModel({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'user_id') required String userId,
    required String topic,
    required String status,
    @JsonKey(name: 'total_questions') required int totalQuestions,
    @JsonKey(name: 'correct_count') required int correctCount,
    required double accuracy,
    @JsonKey(name: 'total_points') required int totalPoints,
    @JsonKey(name: 'total_time_ms') required int totalTimeMs,
    @JsonKey(name: 'max_combo') required int maxCombo,
    @JsonKey(name: 'difficulty_start') required int difficultyStart,
    @JsonKey(name: 'difficulty_end') required int difficultyEnd,
    @JsonKey(name: 'started_at') required DateTime startedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    required List<ResultDetailModel> results,
  }) = _SessionResultModel;

  factory SessionResultModel.fromJson(Map<String, dynamic> json) =>
      _$SessionResultModelFromJson(json);
}

@freezed
abstract class ResultDetailModel with _$ResultDetailModel {
  const factory ResultDetailModel({
    required String id,
    @JsonKey(name: 'question_text') required String questionText,
    @JsonKey(name: 'correct_answer') required double correctAnswer,
    @JsonKey(name: 'user_answer') required double userAnswer,
    @JsonKey(name: 'is_correct') required bool isCorrect,
    @JsonKey(name: 'points_earned') required int pointsEarned,
    @JsonKey(name: 'combo_count') required int comboCount,
    @JsonKey(name: 'combo_multiplier') required double comboMultiplier,
    @JsonKey(name: 'time_taken_ms') int? timeTakenMs,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ResultDetailModel;

  factory ResultDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ResultDetailModelFromJson(json);
}
