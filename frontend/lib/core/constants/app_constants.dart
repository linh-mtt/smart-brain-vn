/// Application-wide constants.
abstract final class AppConstants {
  /// Application name displayed in headers and about screens.
  static const String appName = 'SmartMath Kids';

  /// Minimum password length for registration and validation.
  static const int minPasswordLength = 8;

  /// Maximum username length.
  static const int maxUsernameLength = 50;

  /// Minimum username length.
  static const int minUsernameLength = 3;

  // ─── Animation Durations ───────────────────────────────────────────

  /// Short animation for micro-interactions (200ms).
  static const Duration animationShort = Duration(milliseconds: 200);

  /// Medium animation for transitions (400ms).
  static const Duration animationMedium = Duration(milliseconds: 400);

  /// Long animation for complex sequences (600ms).
  static const Duration animationLong = Duration(milliseconds: 600);

  /// Page transition duration (300ms).
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  // ─── Defaults ──────────────────────────────────────────────────────

  /// Default grade level for new students.
  static const int defaultGradeLevel = 1;

  /// Minimum grade level.
  static const int minGradeLevel = 1;

  /// Maximum grade level.
  static const int maxGradeLevel = 6;

  // ─── XP & Leveling ────────────────────────────────────────────────

  /// XP thresholds for each level. Index = level number.
  static const List<int> xpLevelThresholds = [
    0, // Level 0
    100, // Level 1
    300, // Level 2
    600, // Level 3
    1000, // Level 4
    1500, // Level 5
    2200, // Level 6
    3000, // Level 7
    4000, // Level 8
    5500, // Level 9
    7500, // Level 10
    10000, // Level 11
  ];

  /// Returns the level for the given total XP.
  static int levelForXp(int xp) {
    for (int i = xpLevelThresholds.length - 1; i >= 0; i--) {
      if (xp >= xpLevelThresholds[i]) return i;
    }
    return 0;
  }

  /// Returns XP progress within the current level as a 0.0–1.0 fraction.
  static double xpProgressFraction(int xp) {
    final level = levelForXp(xp);
    if (level >= xpLevelThresholds.length - 1) return 1.0;
    final currentThreshold = xpLevelThresholds[level];
    final nextThreshold = xpLevelThresholds[level + 1];
    return (xp - currentThreshold) / (nextThreshold - currentThreshold);
  }
}
