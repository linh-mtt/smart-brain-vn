import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/answer_feedback_model.dart';
import '../models/exercise_model.dart';

/// Remote data source for exercise operations.
///
/// Communicates with the backend API via [ApiClient].
class ExerciseRemoteDatasource {
  ExerciseRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Generates exercises for the given topic and difficulty.
  Future<List<ExerciseModel>> generateExercises({
    required String topic,
    required String difficulty,
    int count = 5,
  }) async {
    try {
      return await _apiClient.post<List<ExerciseModel>>(
        '${ApiConstants.exercisesEndpoint}/generate',
        data: {'topic': topic, 'difficulty': difficulty, 'count': count},
        fromJson: (json) => (json as List<dynamic>)
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to generate exercises: ${e.toString()}',
      );
    }
  }

  /// Submits an answer for an exercise.
  Future<AnswerFeedbackModel> submitAnswer({
    required String exerciseId,
    required double answer,
    int? timeTakenMs,
  }) async {
    try {
      return await _apiClient.post<AnswerFeedbackModel>(
        ApiConstants.submitAnswerEndpoint,
        data: {
          'exercise_id': exerciseId,
          'answer': answer,
          if (timeTakenMs != null) 'time_taken_ms': timeTakenMs,
        },
        fromJson: (json) =>
            AnswerFeedbackModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to submit answer: ${e.toString()}',
      );
    }
  }
}
