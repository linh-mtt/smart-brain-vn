/// Tracks scores for both players in a competition match.
class MatchScoreEntity {
  const MatchScoreEntity({
    required this.playerId,
    required this.playerScore,
    required this.opponentId,
    required this.opponentScore,
    required this.currentStreak,
    required this.opponentStreak,
  });

  final String playerId;
  final int playerScore;
  final String opponentId;
  final int opponentScore;
  final int currentStreak;
  final int opponentStreak;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchScoreEntity &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          opponentId == other.opponentId;

  @override
  int get hashCode => Object.hash(playerId, opponentId);
}
