import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/match_result_entity.dart';
import '../../domain/repositories/competition_repository.dart';
import '../datasources/competition_websocket_datasource.dart';

/// Implementation of [CompetitionRepository].
///
/// Coordinates WebSocket operations and HTTP fallbacks for match results.
class CompetitionRepositoryImpl implements CompetitionRepository {
  CompetitionRepositoryImpl({
    required CompetitionWebSocketDatasource datasource,
  }) : _datasource = datasource;

  final CompetitionWebSocketDatasource _datasource;
  // ignore: unused_field
  String? _currentMatchId;
  Completer<Result<String>>? _findMatchCompleter;
  StreamSubscription<MatchEvent>? _matchFoundSubscription;

  @override
  Future<Result<String>> findMatch() async {
    try {
      _findMatchCompleter = Completer<Result<String>>();

      // Listen for match_found event.
      _matchFoundSubscription = _datasource.matchEvents.listen((event) {
        if (event is MatchFoundEvent && _findMatchCompleter != null) {
          _currentMatchId = event.matchId;
          if (!_findMatchCompleter!.isCompleted) {
            _findMatchCompleter!.complete(Result.success(event.matchId));
          }
          _matchFoundSubscription?.cancel();
          _matchFoundSubscription = null;
        }
      });

      // Send find_match request.
      _datasource.findMatch();

      // Wait with timeout.
      return await _findMatchCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _matchFoundSubscription?.cancel();
          _matchFoundSubscription = null;
          return const Result.failure(
            ServerFailure(message: 'Match search timed out. Try again!'),
          );
        },
      );
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to find match: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> submitAnswer({
    required String matchId,
    required String questionId,
    required double answer,
    int? timeTakenMs,
  }) async {
    try {
      _datasource.submitAnswer(
        matchId: matchId,
        questionId: questionId,
        answer: answer,
        timeTakenMs: timeTakenMs,
      );
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to submit answer: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<MatchResultEntity>> getMatchResult({
    required String matchId,
  }) async {
    try {
      // Listen for the next match_complete event if not yet received.
      final completer = Completer<MatchResultEntity>();

      final subscription = _datasource.matchEvents.listen((event) {
        if (event is MatchCompleteEvent && !completer.isCompleted) {
          completer.complete(event.result);
        }
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const ServerException(
            message: 'Timed out waiting for match result.',
          );
        },
      );

      await subscription.cancel();
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get match result: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> disconnect() async {
    try {
      _matchFoundSubscription?.cancel();
      _matchFoundSubscription = null;
      await _datasource.disconnect();
      _currentMatchId = null;
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to disconnect: ${e.toString()}'),
      );
    }
  }
}
