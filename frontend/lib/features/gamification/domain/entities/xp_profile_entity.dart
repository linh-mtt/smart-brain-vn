/// Domain entity representing a user's XP profile.
///
/// Contains level, XP progress, unlocked achievements, and active theme.
class XpProfileEntity {
  const XpProfileEntity({
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
    required this.xpProgressPercent,
    required this.unlockedAchievements,
    this.activeTheme,
  });

  /// User identifier.
  final String userId;

  /// Total accumulated XP.
  final int totalXp;

  /// Current level.
  final int currentLevel;

  /// XP earned in the current level.
  final int xpInCurrentLevel;

  /// XP required to reach the next level.
  final int xpForNextLevel;

  /// Progress percentage toward next level (0–100).
  final double xpProgressPercent;

  /// Achievements the user has unlocked.
  final List<UnlockedAchievementEntity> unlockedAchievements;

  /// The currently active theme, if any.
  final ThemeEntity? activeTheme;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpProfileEntity &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'XpProfileEntity(userId: $userId, level: $currentLevel, xp: $totalXp)';
}

/// Domain entity for an unlocked achievement.
class UnlockedAchievementEntity {
  const UnlockedAchievementEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rewardPoints,
    required this.unlockedAt,
  });

  /// Achievement identifier.
  final String id;

  /// Achievement name/title.
  final String name;

  /// Achievement description.
  final String description;

  /// Emoji icon.
  final String emoji;

  /// Points rewarded on unlock.
  final int rewardPoints;

  /// When the achievement was unlocked.
  final DateTime unlockedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnlockedAchievementEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UnlockedAchievementEntity(id: $id, name: $name)';
}

/// Domain entity for a theme.
class ThemeEntity {
  const ThemeEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredLevel,
    required this.requiredXp,
    required this.isPremium,
    required this.isUnlocked,
    required this.isActive,
    required this.canUnlock,
  });

  /// Theme identifier.
  final String id;

  /// Theme name.
  final String name;

  /// Theme description.
  final String description;

  /// Emoji icon.
  final String emoji;

  /// Minimum level required to unlock.
  final int requiredLevel;

  /// Minimum XP required to unlock.
  final int requiredXp;

  /// Whether this is a premium theme.
  final bool isPremium;

  /// Whether the user has unlocked this theme.
  final bool isUnlocked;

  /// Whether this theme is currently active.
  final bool isActive;

  /// Whether the user meets requirements to unlock.
  final bool canUnlock;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ThemeEntity(id: $id, name: $name, isUnlocked: $isUnlocked)';
}
