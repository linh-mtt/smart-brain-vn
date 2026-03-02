import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/exceptions.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/competition/data/datasources/competition_websocket_datasource.dart';
import 'package:smart_math_kids/features/competition/data/repositories/competition_repository_impl.dart';
import 'package:smart_math_kids/features/competition/domain/entities/match_result_entity.dart';
import 'package:smart_math_kids/features/competition/domain/entities/opponent_entity.dart';

class MockCompetitionWebSocketDatasource extends Mock
    implements CompetitionWebSocketDatasource {}

void main() {
  late MockCompetitionWebSocketDatasource mockDatasource;
  late CompetitionRepositoryImpl repository;
  late StreamController<MatchEvent> matchEventsController;

  setUp(() {
    mockDatasource = MockCompetitionWebSocketDatasource();
    matchEventsController = StreamController<MatchEvent>.broadcast();
    repository = CompetitionRepositoryImpl(datasource: mockDatasource);
  });

  tearDown(() {
    matchEventsController.close();
  });

  final tOpponent = const OpponentEntity(
    id: 'opp-1',
    username: 'opponent_user',
    displayName: 'Opponent Player',
    avatarUrl: 'https://example.com/avatar.png',
    eloRating: 1500,
  );

  final tMatchResultEntity = const MatchResultEntity(
    matchId: 'match-1',
    isVictory: true,
    playerScore: 80,
    opponentScore: 60,
    questionsAnswered: 10,
    correctAnswers: 8,
    accuracy: 80.0,
    totalTimeMs: 30000,
    pointsEarned: 150,
    eloChange: 25,
    opponentName: 'Opponent Player',
  );

  group('findMatch', () {
    test(
      'returns Result.success with matchId on successful match found event',
      () async {
        when(
          () => mockDatasource.matchEvents,
        ).thenAnswer((_) => matchEventsController.stream);
        when(() => mockDatasource.findMatch()).thenReturn(null);

        final findMatchFuture = repository.findMatch();

        // Simulate server sending match_found event
        await Future.delayed(const Duration(milliseconds: 100));
        matchEventsController.add(
          MatchFoundEvent(
            matchId: 'match-1',
            opponent: tOpponent,
            totalQuestions: 10,
          ),
        );

        final result = await findMatchFuture;

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, equals('match-1'));
      },
    );

    test('returns ServerFailure on AppException (ServerException)', () async {
      when(
        () => mockDatasource.matchEvents,
      ).thenAnswer((_) => matchEventsController.stream);
      when(
        () => mockDatasource.findMatch(),
      ).thenThrow(ServerException(message: 'Server error'));

      final result = await repository.findMatch();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns UnknownFailure on generic exception', () async {
      when(
        () => mockDatasource.matchEvents,
      ).thenThrow(Exception('Unexpected error'));

      final result = await repository.findMatch();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('submitAnswer', () {
    test(
      'returns Result.success with null on successful answer submission',
      () async {
        when(
          () => mockDatasource.submitAnswer(
            matchId: any(named: 'matchId'),
            questionId: any(named: 'questionId'),
            answer: any(named: 'answer'),
            timeTakenMs: any(named: 'timeTakenMs'),
          ),
        ).thenReturn(null);

        final result = await repository.submitAnswer(
          matchId: 'match-1',
          questionId: 'q1',
          answer: 42.0,
          timeTakenMs: 5000,
        );

        expect(result.isSuccess, isTrue);
        // Result<void>.dataOrNull is void — just check isSuccess
      },
    );

    test('returns Result.success with null when timeTakenMs is null', () async {
      when(
        () => mockDatasource.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).thenReturn(null);

      final result = await repository.submitAnswer(
        matchId: 'match-1',
        questionId: 'q2',
        answer: 15.0,
      );

      expect(result.isSuccess, isTrue);
        // Result<void>.dataOrNull is void — just check isSuccess
    });

    test('returns ServerFailure on AppException (ServerException)', () async {
      when(
        () => mockDatasource.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).thenThrow(ServerException(message: 'Submit failed'));

      final result = await repository.submitAnswer(
        matchId: 'match-1',
        questionId: 'q1',
        answer: 42.0,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('returns UnknownFailure on generic exception', () async {
      when(
        () => mockDatasource.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await repository.submitAnswer(
        matchId: 'match-1',
        questionId: 'q1',
        answer: 42.0,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('getMatchResult', () {
    test(
      'returns Result.success with MatchResultEntity on match_complete event',
      () async {
        when(
          () => mockDatasource.matchEvents,
        ).thenAnswer((_) => matchEventsController.stream);

        final getResultFuture = repository.getMatchResult(matchId: 'match-1');

        // Simulate server sending match_complete event
        await Future.delayed(const Duration(milliseconds: 100));
        matchEventsController.add(
          MatchCompleteEvent(result: tMatchResultEntity),
        );

        final result = await getResultFuture;

        expect(result.isSuccess, isTrue);
        final entity = result.dataOrNull!;
        expect(entity.matchId, 'match-1');
        expect(entity.isVictory, isTrue);
        expect(entity.playerScore, 80);
        expect(entity.opponentScore, 60);
        expect(entity.questionsAnswered, 10);
        expect(entity.correctAnswers, 8);
        expect(entity.accuracy, 80.0);
        expect(entity.totalTimeMs, 30000);
        expect(entity.pointsEarned, 150);
        expect(entity.eloChange, 25);
        expect(entity.opponentName, 'Opponent Player');
      },
    );

    test(
      'returns ServerFailure when matchEvents getter throws AppException',
      () async {
        when(
          () => mockDatasource.matchEvents,
        ).thenThrow(ServerException(message: 'Stream error'));

        final result = await repository.getMatchResult(matchId: 'match-1');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ServerFailure>());
      },
    );

    test(
      'returns UnknownFailure on generic exception from matchEvents',
      () async {
        when(
          () => mockDatasource.matchEvents,
        ).thenThrow(Exception('Unexpected error'));

        final result = await repository.getMatchResult(matchId: 'match-1');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  group('disconnect', () {
    test('returns Result.success with null on successful disconnect', () async {
      when(() => mockDatasource.disconnect()).thenAnswer((_) async {});

      final result = await repository.disconnect();

      expect(result.isSuccess, isTrue);
        // Result<void>.dataOrNull is void — just check isSuccess
      verify(() => mockDatasource.disconnect()).called(1);
    });

    test('returns UnknownFailure on exception during disconnect', () async {
      when(
        () => mockDatasource.disconnect(),
      ).thenThrow(Exception('Disconnect error'));

      final result = await repository.disconnect();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('cancels matchFoundSubscription when disconnecting', () async {
      when(
        () => mockDatasource.matchEvents,
      ).thenAnswer((_) => matchEventsController.stream);
      when(() => mockDatasource.findMatch()).thenReturn(null);
      when(() => mockDatasource.disconnect()).thenAnswer((_) async {});

      // First, start finding a match
      repository.findMatch();

      await Future.delayed(const Duration(milliseconds: 50));

      // Then disconnect before match is found
      final disconnectResult = await repository.disconnect();

      expect(disconnectResult.isSuccess, isTrue);
      verify(() => mockDatasource.disconnect()).called(1);
    });
  });
}
