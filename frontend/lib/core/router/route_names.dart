/// Route name constants for navigation.
///
/// Centralized route names prevent typos and make refactoring easy.
abstract final class RouteNames {
  // ─── Auth Routes ──────────────────────────────────────────────────

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';

  // ─── Main Routes (Shell) ──────────────────────────────────────────

  static const String home = 'home';
  static const String exercise = 'exercise';
  static const String exerciseTopic = 'exerciseTopic';
  static const String progress = 'progress';
  static const String profile = 'profile';

  // ─── Detail Routes ────────────────────────────────────────────────

  static const String achievements = 'achievements';
  static const String settings = 'settings';
  static const String parentDashboard = 'parentDashboard';
  static const String practice = 'practice';
  static const String practiceResult = 'practiceResult';
  static const String learningTips = 'learningTips';
  static const String tipDetail = 'tipDetail';
  static const String competitionLobby = 'competitionLobby';
  static const String competitionMatch = 'competitionMatch';
  static const String competitionResult = 'competitionResult';

  static const String themeSelection = 'themeSelection';

  // ─── Route Paths ──────────────────────────────────────────────────

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String homePath = '/home';
  static const String exercisePath = '/exercise';
  static const String exerciseTopicPath = '/exercise/:topic/:difficulty';
  static const String progressPath = '/progress';
  static const String profilePath = '/profile';
  static const String achievementsPath = '/achievements';
  static const String settingsPath = '/settings';
  static const String parentDashboardPath = '/parent';
  static const String practicePath = '/practice';
  static const String practiceResultPath = '/practice/result/:id';
  static const String learningTipsPath = '/learning-tips';
  static const String tipDetailPath = '/learning-tips/:tipId';
  static const String competitionLobbyPath = '/competition';
  static const String competitionMatchPath = '/competition/match';
  static const String competitionResultPath = '/competition/result';
  static const String themeSelectionPath = '/themes';

}
