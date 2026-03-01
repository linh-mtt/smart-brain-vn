/// Domain entity representing an achievement badge.
///
/// This is a plain Dart class that represents the core achievement
/// concept in the domain layer, independent of data sources.
class AchievementEntity {
  const AchievementEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rewardPoints,
    required this.isUnlocked,
    this.unlockedAt,
  });

  /// Unique achievement identifier.
  final String id;

  /// Achievement name/title.
  final String name;

  /// Achievement description.
  final String description;

  /// Emoji icon for the achievement.
  final String emoji;

  /// Points rewarded when achievement is unlocked.
  final int rewardPoints;

  /// Whether the achievement has been unlocked by the user.
  final bool isUnlocked;

  /// Timestamp when the achievement was unlocked.
  final DateTime? unlockedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AchievementEntity(id: $id, name: $name, isUnlocked: $isUnlocked)';
}
