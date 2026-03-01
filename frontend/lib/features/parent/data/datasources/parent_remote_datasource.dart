import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/child_progress_model.dart';
import '../models/child_summary_model.dart';

/// Remote data source for parent dashboard operations.
///
/// Communicates with the backend API via [ApiClient].
class ParentRemoteDatasource {
  ParentRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Gets all children associated with the parent.
  ///
  /// Backend route: GET /api/v1/parent/children
  Future<List<ChildSummaryModel>> getChildren() async {
    try {
      return await _apiClient.get<List<ChildSummaryModel>>(
        '/parent/children',
        fromJson: (json) => (json as List<dynamic>)
            .map((e) => ChildSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get children: ${e.toString()}');
    }
  }

  /// Gets detailed progress for a specific child.
  ///
  /// Backend route: GET /api/v1/parent/child/{childId}/progress
  Future<ChildProgressModel> getChildProgress(String childId) async {
    try {
      return await _apiClient.get<ChildProgressModel>(
        '/parent/child/$childId/progress',
        fromJson: (json) =>
            ChildProgressModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get child progress: ${e.toString()}',
      );
    }
  }

  /// Updates learning goals for a specific child.
  ///
  /// Backend route: PUT /api/v1/parent/child/{childId}/goals
  Future<void> updateChildGoals(
    String childId, {
    int? dailyExerciseTarget,
    int? dailyTimeTargetMinutes,
    List<String>? activeTopics,
  }) async {
    final data = <String, dynamic>{};
    if (dailyExerciseTarget != null) {
      data['daily_exercise_target'] = dailyExerciseTarget;
    }
    if (dailyTimeTargetMinutes != null) {
      data['daily_time_target_minutes'] = dailyTimeTargetMinutes;
    }
    if (activeTopics != null) {
      data['active_topics'] = activeTopics;
    }

    try {
      await _apiClient.put<dynamic>('/parent/child/$childId/goals', data: data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to update child goals: ${e.toString()}',
      );
    }
  }
}
