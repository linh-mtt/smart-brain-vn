import 'package:freezed_annotation/freezed_annotation.dart';

import 'practice_question_model.dart';

part 'start_session_model.freezed.dart';
part 'start_session_model.g.dart';

@freezed
abstract class StartSessionModel with _$StartSessionModel {
  const factory StartSessionModel({
    @JsonKey(name: 'session_id') required String sessionId,
    required String topic,
    @JsonKey(name: 'difficulty_start') required int difficultyStart,
    required List<PracticeQuestionModel> questions,
  }) = _StartSessionModel;

  factory StartSessionModel.fromJson(Map<String, dynamic> json) =>
      _$StartSessionModelFromJson(json);
}
