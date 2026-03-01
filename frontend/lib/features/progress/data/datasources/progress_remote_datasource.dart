import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/progress_summary_model.dart';
import '../models/topic_progress_model.dart';

/// Remote data source for progress operations.
///
/// Communicates with the backend API via [ApiClient].
class ProgressRemoteDatasource {
  ProgressRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The list of all math topics.
  static const _allTopics = [
    'addition',
    'subtraction',
    'multiplication',
    'division',
  ];

  /// Gets the user's overall progress summary.
  Future<ProgressSummaryModel> getProgressSummary() async {
    try {
      return await _apiClient.get<ProgressSummaryModel>(
        '${ApiConstants.progressEndpoint}/summary',
        fromJson: (json) =>
            ProgressSummaryModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get progress summary: ${e.toString()}',
      );
    }
  }

  /// Gets the user's progress for a specific topic.
  Future<TopicProgressModel> getTopicProgress(String topic) async {
    try {
      return await _apiClient.get<TopicProgressModel>(
        '${ApiConstants.progressEndpoint}/topic/$topic',
        fromJson: (json) =>
            TopicProgressModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get topic progress: ${e.toString()}',
      );
    }
  }

  /// Gets the user's progress for all topics.
  Future<List<TopicProgressModel>> getAllTopicProgress() async {
    try {
      final results = await Future.wait(
        _allTopics.map((topic) => getTopicProgress(topic)),
      );
      return results;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get all topic progress: ${e.toString()}',
      );
    }
  }
}
