import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/achievement_model.dart';

/// Remote data source for achievement operations.
///
/// Communicates with the backend API via [ApiClient].
class AchievementRemoteDatasource {
  AchievementRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Gets all achievements for the current user.
  Future<List<AchievementModel>> getAchievements() async {
    try {
      return await _apiClient.get<List<AchievementModel>>(
        ApiConstants.achievementsEndpoint,
        fromJson: (json) => (json as List<dynamic>)
            .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get achievements: ${e.toString()}',
      );
    }
  }
}
