import '../../config/env_config.dart';

/// API configuration constants.
///
/// All endpoint paths and configuration for communicating with the backend.
abstract final class ApiConstants {
  /// Base URL for the API server.
  /// Override via .env file (highest priority) or String.fromEnvironment.
  static String get baseUrl {
    final envUrl = EnvConfig.maybeGet('API_BASE_URL');
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
  }

  /// WebSocket base URL (derived from baseUrl).
  /// Replaces http:// with ws:// and https:// with wss://.
  static String get wsBaseUrl {
    final url = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$url/api/$apiVersion/ws';
  }

  /// API version prefix.
  static const String apiVersion = 'v1';

  /// Full API base path.
  static String get apiBasePath => '$baseUrl/api/$apiVersion';

  /// Connection timeout in milliseconds.
  static const int connectTimeout = 10000;

  /// Receive timeout in milliseconds.
  static const int receiveTimeout = 10000;

  /// Send timeout in milliseconds.
  static const int sendTimeout = 10000;

  // ─── Auth Endpoints ───────────────────────────────────────────────

  static const String loginEndpoint = '/auth/login';
  static const String googleLoginEndpoint = '/auth/google';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/auth/profile';
  static const String updateProfileEndpoint = '/auth/profile';

  // ─── Exercise Endpoints ───────────────────────────────────────────

  static const String exercisesEndpoint = '/exercises';
  static const String exerciseByTopicEndpoint = '/exercises/topic';
  static const String submitAnswerEndpoint = '/exercises/submit';

  // ─── Practice Session Endpoints ──────────────────────────────────

  static const String practiceStartEndpoint = '/practice/start';
  static const String practiceAnswerEndpoint = '/practice/answer';
  static const String practiceResultEndpoint = '/practice/result';
  static const String practiceQuestionsEndpoint = '/practice/questions';
  static const String practiceSubmitEndpoint = '/practice/submit';

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

  // ─── Competition Endpoints ──────────────────────────────────────

  static const String competitionMatchEndpoint = '/competition/match';
  static const String competitionResultEndpoint = '/competition/result';

  // ─── XP / Gamification Endpoints ────────────────────────────────

  static const String xpProfileEndpoint = '/xp/profile';
  static const String xpThemesEndpoint = '/xp/themes';

  /// WebSocket reconnection delay in milliseconds.
  static const int wsReconnectDelay = 1000;

  /// Maximum WebSocket reconnection delay in milliseconds.
  static const int wsMaxReconnectDelay = 30000;

  /// Maximum number of WebSocket reconnection attempts.
  static const int wsMaxReconnectAttempts = 10;
}
