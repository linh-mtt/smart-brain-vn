import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/theme_list_model.dart';
import '../models/theme_model.dart';
import '../models/xp_profile_model.dart';

/// Remote data source for gamification (XP/level/theme) operations.
///
/// Communicates with the backend API via [ApiClient].
class GamificationRemoteDatasource {
  GamificationRemoteDatasource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String _profilePath = '/xp/profile';
  static const String _themesPath = '/xp/themes';

  /// Gets the current user's XP profile.
  Future<XpProfileModel> getXpProfile() async {
    try {
      return await _apiClient.get<XpProfileModel>(
        _profilePath,
        fromJson: (json) =>
            XpProfileModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get XP profile: ${e.toString()}',
      );
    }
  }

  /// Gets all available themes with unlock status.
  Future<ThemeListModel> getThemes() async {
    try {
      return await _apiClient.get<ThemeListModel>(
        _themesPath,
        fromJson: (json) =>
            ThemeListModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get themes: ${e.toString()}');
    }
  }

  /// Unlocks a theme by ID.
  Future<ThemeModel> unlockTheme(String themeId) async {
    try {
      return await _apiClient.post<ThemeModel>(
        '$_themesPath/$themeId/unlock',
        fromJson: (json) => ThemeModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to unlock theme: ${e.toString()}');
    }
  }

  /// Activates a theme by ID (deactivates all others).
  Future<void> activateTheme(String themeId) async {
    try {
      await _apiClient.put<dynamic>('$_themesPath/$themeId/activate');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to activate theme: ${e.toString()}',
      );
    }
  }
}
