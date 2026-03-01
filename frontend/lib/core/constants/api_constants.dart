/// API configuration constants.
///
/// All endpoint paths and configuration for communicating with the backend.
abstract final class ApiConstants {
  /// Base URL for the API server.
  /// Override via environment variable or String.fromEnvironment.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// API version prefix.
  static const String apiVersion = 'v1';

  /// Full API base path.
  static String get apiBasePath => '$baseUrl/api/$apiVersion';

  /// Connection timeout in milliseconds.
  static const int connectTimeout = 30000;

  /// Receive timeout in milliseconds.
  static const int receiveTimeout = 30000;

  /// Send timeout in milliseconds.
  static const int sendTimeout = 30000;

  // ─── Auth Endpoints ───────────────────────────────────────────────

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/auth/profile';
  static const String updateProfileEndpoint = '/auth/profile';

  // ─── Exercise Endpoints ───────────────────────────────────────────

  static const String exercisesEndpoint = '/exercises';
  static const String exerciseByTopicEndpoint = '/exercises/topic';
  static const String submitAnswerEndpoint = '/exercises/submit';

  // ─── Progress Endpoints ───────────────────────────────────────────

  static const String progressEndpoint = '/progress';
  static const String progressStatsEndpoint = '/progress/stats';
  static const String leaderboardEndpoint = '/progress/leaderboard';

  // ─── Achievement Endpoints ────────────────────────────────────────

  static const String achievementsEndpoint = '/achievements';
  static const String claimRewardEndpoint = '/achievements/claim';

  // ─── Parent Dashboard Endpoints ───────────────────────────────────

  static const String parentDashboardEndpoint = '/parent/dashboard';
  static const String parentChildrenEndpoint = '/parent/children';
  static const String parentSettingsEndpoint = '/parent/settings';
}
