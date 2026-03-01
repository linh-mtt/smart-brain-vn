import 'package:freezed_annotation/freezed_annotation.dart';

part 'practice_question_model.freezed.dart';
part 'practice_question_model.g.dart';

@freezed
abstract class PracticeQuestionModel with _$PracticeQuestionModel {
  const factory PracticeQuestionModel({
    required String id,
    @JsonKey(name: 'question_text') required String questionText,
    @JsonKey(name: 'correct_answer') required double correctAnswer,
    required List<String> options,
    required String explanation,
    required String topic,
    @JsonKey(name: 'difficulty_level') required int difficultyLevel,
  }) = _PracticeQuestionModel;

  factory PracticeQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeQuestionModelFromJson(json);
}
