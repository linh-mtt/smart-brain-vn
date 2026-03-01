import '../../../../core/errors/failures.dart';
import '../entities/practice_question_entity.dart';
import '../entities/session_feedback_entity.dart';
import '../entities/practice_result_entity.dart';

abstract class PracticeRepository {
  /// Starts a new practice session. Returns session ID + questions.
  Future<
    Result<
      ({
        String sessionId,
        String topic,
        int difficultyStart,
        List<PracticeQuestionEntity> questions,
      })
    >
  >
  startSession({required String topic, int questionCount = 5});

  /// Submits an answer for a question in a session.
  Future<Result<SessionFeedbackEntity>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String topic,
    required int difficultyLevel,
    required String questionText,
    required double correctAnswer,
    required double answer,
    int? timeTakenMs,
  });

  /// Gets the result of a completed session.
  Future<Result<PracticeResultEntity>> getResult({required String sessionId});
}
