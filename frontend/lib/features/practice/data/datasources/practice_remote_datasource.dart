import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/session_feedback_model.dart';
import '../models/session_result_model.dart';
import '../models/start_session_model.dart';

/// Remote data source for practice session operations.
///
/// Communicates with the backend API via [ApiClient].
class PracticeRemoteDatasource {
  PracticeRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Starts a new practice session.
  Future<StartSessionModel> startSession({
    required String topic,
    int questionCount = 5,
  }) async {
    try {
      return await _apiClient.post<StartSessionModel>(
        ApiConstants.practiceStartEndpoint,
        data: {'topic': topic, 'question_count': questionCount},
        fromJson: (json) =>
            StartSessionModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to start practice session: ${e.toString()}',
      );
    }
  }

  /// Submits an answer for a question in a session.
  Future<SessionFeedbackModel> submitAnswer({
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
      return await _apiClient.post<SessionFeedbackModel>(
        ApiConstants.practiceAnswerEndpoint,
        data: {
          'session_id': sessionId,
          'question_id': questionId,
          'topic': topic,
          'difficulty_level': difficultyLevel,
          'question_text': questionText,
          'correct_answer': correctAnswer,
          'answer': answer,
          if (timeTakenMs != null) 'time_taken_ms': timeTakenMs,
        },
        fromJson: (json) =>
            SessionFeedbackModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to submit practice answer: ${e.toString()}',
      );
    }
  }

  /// Gets the result of a completed session.
  Future<SessionResultModel> getResult({required String sessionId}) async {
    try {
      return await _apiClient.get<SessionResultModel>(
        '${ApiConstants.practiceResultEndpoint}/$sessionId',
        fromJson: (json) =>
            SessionResultModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get practice result: ${e.toString()}',
      );
    }
  }
}
