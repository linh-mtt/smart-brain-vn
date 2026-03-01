import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/leaderboard_entry_model.dart';

/// Remote data source for leaderboard operations.
///
/// Communicates with the backend API via [ApiClient].
class LeaderboardRemoteDatasource {
  LeaderboardRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Gets leaderboard entries, optionally filtered by [period].
  ///
  /// Backend route: GET /api/v1/leaderboard?period={period}
  Future<List<LeaderboardEntryModel>> getLeaderboard({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) {
        queryParams['period'] = period;
      }

      return await _apiClient.get<List<LeaderboardEntryModel>>(
        '/leaderboard',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) => (json as List<dynamic>)
            .map(
              (e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get leaderboard: ${e.toString()}',
      );
    }
  }
}
