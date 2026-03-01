import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/practice_question_entity.dart';
import '../../domain/entities/practice_result_entity.dart';
import '../../domain/entities/session_feedback_entity.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_datasource.dart';

/// Implementation of [PracticeRepository] that coordinates with
/// the remote data source.
///
/// Handles error mapping from exceptions to domain failures.
class PracticeRepositoryImpl implements PracticeRepository {
  PracticeRepositoryImpl({required PracticeRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  final PracticeRemoteDatasource _remoteDatasource;

  @override
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
  startSession({required String topic, int questionCount = 5}) async {
    try {
      final model = await _remoteDatasource.startSession(
        topic: topic,
        questionCount: questionCount,
      );

      final questions = model.questions
          .map(
            (q) => PracticeQuestionEntity(
              id: q.id,
              questionText: q.questionText,
              correctAnswer: q.correctAnswer,
              options: q.options,
              explanation: q.explanation,
              topic: q.topic,
              difficultyLevel: q.difficultyLevel,
            ),
          )
          .toList();

      return Result.success((
        sessionId: model.sessionId,
        topic: model.topic,
        difficultyStart: model.difficultyStart,
        questions: questions,
      ));
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to start practice session: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<SessionFeedbackEntity>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String topic,
    required int difficultyLevel,
    required String questionText,
    required double correctAnswer,
    required double answer,
    int? timeTakenMs,
  }) async {
    try {
      final model = await _remoteDatasource.submitAnswer(
        sessionId: sessionId,
        questionId: questionId,
        topic: topic,
        difficultyLevel: difficultyLevel,
        questionText: questionText,
        correctAnswer: correctAnswer,
        answer: answer,
        timeTakenMs: timeTakenMs,
      );

      return Result.success(
        SessionFeedbackEntity(
          isCorrect: model.isCorrect,
          correctAnswer: model.correctAnswer,
          pointsEarned: model.pointsEarned,
          comboCount: model.comboCount,
          comboMultiplier: model.comboMultiplier,
          maxCombo: model.maxCombo,
          newDifficulty: model.newDifficulty,
          eloRating: model.eloRating,
          streak: model.streak,
          weakTopics: model.weakTopics,
          sessionProgress: SessionProgressEntity(
            totalQuestions: model.sessionProgress.totalQuestions,
            correctCount: model.sessionProgress.correctCount,
            totalPoints: model.sessionProgress.totalPoints,
            totalTimeMs: model.sessionProgress.totalTimeMs,
            accuracy: model.sessionProgress.accuracy,
          ),
        ),
      );
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to submit practice answer: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<PracticeResultEntity>> getResult({
    required String sessionId,
  }) async {
    try {
      final model = await _remoteDatasource.getResult(sessionId: sessionId);

      return Result.success(
        PracticeResultEntity(
          sessionId: model.sessionId,
          userId: model.userId,
          topic: model.topic,
          status: model.status,
          totalQuestions: model.totalQuestions,
          correctCount: model.correctCount,
          accuracy: model.accuracy,
          totalPoints: model.totalPoints,
          totalTimeMs: model.totalTimeMs,
          maxCombo: model.maxCombo,
          difficultyStart: model.difficultyStart,
          difficultyEnd: model.difficultyEnd,
          startedAt: model.startedAt,
          completedAt: model.completedAt,
          results: model.results
              .map(
                (r) => ResultDetailEntity(
                  id: r.id,
                  questionText: r.questionText,
                  correctAnswer: r.correctAnswer,
                  userAnswer: r.userAnswer,
                  isCorrect: r.isCorrect,
                  pointsEarned: r.pointsEarned,
                  comboCount: r.comboCount,
                  comboMultiplier: r.comboMultiplier,
                  timeTakenMs: r.timeTakenMs,
                  createdAt: r.createdAt,
                ),
              )
              .toList(),
        ),
      );
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to get practice result: ${e.toString()}',
        ),
      );
    }
  }
}
