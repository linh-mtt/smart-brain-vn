/// Represents the final result of a completed competition match.
class MatchResultEntity {
  const MatchResultEntity({
    required this.matchId,
    required this.isVictory,
    required this.playerScore,
    required this.opponentScore,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.accuracy,
    required this.totalTimeMs,
    required this.pointsEarned,
    required this.eloChange,
    required this.opponentName,
  });

  final String matchId;
  final bool isVictory;
  final int playerScore;
  final int opponentScore;
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracy;
  final int totalTimeMs;
  final int pointsEarned;
  final int eloChange;
  final String opponentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchResultEntity &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId;

  @override
  int get hashCode => matchId.hashCode;
}
