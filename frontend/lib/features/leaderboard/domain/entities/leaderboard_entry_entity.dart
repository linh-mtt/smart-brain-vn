/// Domain entity representing a leaderboard entry.
///
/// This is a plain Dart class that represents the core leaderboard entry
/// concept in the domain layer, independent of data sources.
class LeaderboardEntryEntity {
  const LeaderboardEntryEntity({
    required this.userId,
    required this.username,
    this.displayName,
    required this.totalPoints,
    required this.rank,
  });

  /// Unique user identifier.
  final String userId;

  /// Username of the player.
  final String username;

  /// Optional display name.
  final String? displayName;

  /// Total points accumulated.
  final int totalPoints;

  /// Current rank on the leaderboard.
  final int rank;

  /// Returns the display name, falling back to username.
  String get effectiveDisplayName => displayName ?? username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntryEntity &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'LeaderboardEntryEntity(userId: $userId, username: $username, rank: $rank)';
}
