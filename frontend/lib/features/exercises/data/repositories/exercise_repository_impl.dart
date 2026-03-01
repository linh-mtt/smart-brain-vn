import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/answer_feedback_entity.dart';
import '../../domain/entities/exercise_entity.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/exercise_remote_datasource.dart';

/// Implementation of [ExerciseRepository] that coordinates with
/// the remote data source.
///
/// Handles error mapping from exceptions to domain failures.
class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl({required ExerciseRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  final ExerciseRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<ExerciseEntity>>> generateExercises({
    required String topic,
    required String difficulty,
    int count = 5,
  }) async {
    try {
      final models = await _remoteDatasource.generateExercises(
        topic: topic,
        difficulty: difficulty,
        count: count,
      );

      final entities = models
          .map(
            (model) => ExerciseEntity(
              id: model.id,
              questionText: model.questionText,
              options: model.options,
              difficulty: model.difficulty,
              topic: model.topic,
            ),
          )
          .toList();

      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to generate exercises: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<AnswerFeedbackEntity>> submitAnswer({
    required String exerciseId,
    required double answer,
    int? timeTakenMs,
  }) async {
    try {
      final model = await _remoteDatasource.submitAnswer(
        exerciseId: exerciseId,
        answer: answer,
        timeTakenMs: timeTakenMs,
      );

      final entity = AnswerFeedbackEntity(
        isCorrect: model.isCorrect,
        correctAnswer: model.correctAnswer,
        pointsEarned: model.pointsEarned,
        explanation: model.explanation,
      );

      return Result.success(entity);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to submit answer: ${e.toString()}'),
      );
    }
  }
}
