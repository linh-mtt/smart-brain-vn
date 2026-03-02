import 'xp_profile_entity.dart';

/// Domain entity representing the result of an XP award.
///
/// Contains info about XP gained, level changes, and newly unlocked achievements.
class XpAwardResultEntity {
  const XpAwardResultEntity({
    required this.xpAwarded,
    required this.totalXp,
    required this.previousLevel,
    required this.currentLevel,
    required this.leveledUp,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
    required this.newlyUnlockedAchievements,
  });

  /// Amount of XP awarded.
  final int xpAwarded;

  /// New total XP after award.
  final int totalXp;

  /// Level before the award.
  final int previousLevel;

  /// Level after the award.
  final int currentLevel;

  /// Whether the user leveled up.
  final bool leveledUp;

  /// XP earned within the current level.
  final int xpInCurrentLevel;

  /// XP required for the next level.
  final int xpForNextLevel;

  /// Achievements unlocked by this XP award.
  final List<UnlockedAchievementEntity> newlyUnlockedAchievements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpAwardResultEntity &&
          runtimeType == other.runtimeType &&
          xpAwarded == other.xpAwarded &&
          totalXp == other.totalXp &&
          currentLevel == other.currentLevel;

  @override
  int get hashCode => Object.hash(xpAwarded, totalXp, currentLevel);

  @override
  String toString() =>
      'XpAwardResultEntity(xpAwarded: $xpAwarded, leveledUp: $leveledUp)';
}
