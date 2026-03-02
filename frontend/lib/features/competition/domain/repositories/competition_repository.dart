import '../../../../core/errors/failures.dart';
import '../entities/match_result_entity.dart';

/// Abstract repository interface for competition operations.
///
/// Defines the contract for match lifecycle management.
abstract class CompetitionRepository {
  /// Finds a match and connects to WebSocket.
  /// Returns the match ID upon successful connection.
  Future<Result<String>> findMatch();

  /// Submits an answer for the current question.
  Future<Result<void>> submitAnswer({
    required String matchId,
    required String questionId,
    required double answer,
    int? timeTakenMs,
  });

  /// Retrieves the final result of a completed match.
  Future<Result<MatchResultEntity>> getMatchResult({required String matchId});

  /// Disconnects from the current match WebSocket.
  Future<Result<void>> disconnect();
}
