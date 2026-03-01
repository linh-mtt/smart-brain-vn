import '../../../../core/errors/failures.dart';
import '../entities/answer_feedback_entity.dart';
import '../entities/exercise_entity.dart';

/// Abstract repository defining exercise operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class ExerciseRepository {
  /// Generates a set of exercises for the given topic and difficulty.
  Future<Result<List<ExerciseEntity>>> generateExercises({
    required String topic,
    required String difficulty,
    int count = 5,
  });

  /// Submits an answer for an exercise and returns feedback.
  Future<Result<AnswerFeedbackEntity>> submitAnswer({
    required String exerciseId,
    required double answer,
    int? timeTakenMs,
  });
}
