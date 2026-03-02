import 'competition_question_entity.dart';
import 'match_result_entity.dart';
import 'match_score_entity.dart';
import 'opponent_entity.dart';

/// The status of a competition match.
enum MatchStatus {
  /// Waiting for an opponent to be found.
  waiting,

  /// Countdown before the match starts.
  countdown,

  /// Match is actively in progress.
  inProgress,

  /// Match has been completed.
  completed,

  /// Connection to the match was lost.
  disconnected,
}

/// Represents a full competition match with all state.
class MatchEntity {
  const MatchEntity({
    required this.id,
    required this.status,
    this.opponent,
    this.currentQuestion,
    required this.questionIndex,
    required this.totalQuestions,
    required this.score,
    required this.timeRemainingSeconds,
    this.matchResult,
  });

  final String id;
  final MatchStatus status;
  final OpponentEntity? opponent;
  final CompetitionQuestionEntity? currentQuestion;
  final int questionIndex;
  final int totalQuestions;
  final MatchScoreEntity score;
  final int timeRemainingSeconds;
  final MatchResultEntity? matchResult;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
