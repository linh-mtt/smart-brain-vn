import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/competition/data/datasources/competition_websocket_datasource.dart';
import 'package:smart_math_kids/features/competition/domain/entities/competition_question_entity.dart';
import 'package:smart_math_kids/features/competition/domain/entities/match_entity.dart';
import 'package:smart_math_kids/features/competition/domain/entities/match_result_entity.dart';
import 'package:smart_math_kids/features/competition/domain/entities/opponent_entity.dart';
import 'package:smart_math_kids/features/competition/domain/repositories/competition_repository.dart';
import 'package:smart_math_kids/features/competition/presentation/notifiers/match_notifier.dart';
import 'package:smart_math_kids/features/competition/presentation/providers/competition_providers.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

class MockCompetitionWebSocketDatasource extends Mock
    implements CompetitionWebSocketDatasource {}

void main() {
  late MockCompetitionRepository mockRepo;
  late MockCompetitionWebSocketDatasource mockDatasource;
  late ProviderContainer container;
  late StreamController<MatchEvent> eventsController;

  final tOpponent = const OpponentEntity(
    id: 'opp-1',
    username: 'rival',
    displayName: 'Rival',
    avatarUrl: 'https://example.com/avatar.png',
    eloRating: 1000,
  );

  final tQuestion = const CompetitionQuestionEntity(
    id: 'q1',
    questionText: '2 + 3',
    correctAnswer: 5.0,
    options: ['3', '4', '5', '6'],
    difficultyLevel: 1,
    topic: 'addition',
  );


  final tResult = const MatchResultEntity(
    matchId: 'match-1',
    isVictory: true,
    playerScore: 80,
    opponentScore: 60,
    questionsAnswered: 10,
    correctAnswers: 8,
    accuracy: 80.0,
    totalTimeMs: 120000,
    pointsEarned: 100,
    eloChange: 15,
    opponentName: 'Rival',
  );

  setUp(() {
    mockRepo = MockCompetitionRepository();
    mockDatasource = MockCompetitionWebSocketDatasource();
    eventsController = StreamController<MatchEvent>.broadcast();

    when(
      () => mockDatasource.matchEvents,
    ).thenAnswer((_) => eventsController.stream);

    container = ProviderContainer(
      overrides: [
        competitionRepositoryProvider.overrideWithValue(mockRepo),
        competitionWebSocketDatasourceProvider.overrideWithValue(
          mockDatasource,
        ),
      ],
    );
    // Keep the autoDispose provider alive for the duration of the test.
    // Without this, container.read() does not retain the provider and it
    // gets disposed between reads, killing the event subscription.
    container.listen(matchNotifierProvider, (_, __) {});
  });

  tearDown(() {
    eventsController.close();
    container.dispose();
  });

  MatchState readState() => container.read(matchNotifierProvider);
  MatchNotifier readNotifier() =>
      container.read(matchNotifierProvider.notifier);

  group('initial state', () {
    test('has correct defaults', () {
      final state = readState();
      expect(state.status, MatchStatus.waiting);
      expect(state.matchId, isNull);
      expect(state.opponent, isNull);
      expect(state.currentQuestion, isNull);
      expect(state.questionIndex, 0);
      expect(state.totalQuestions, 10);
      expect(state.playerScore, 0);
      expect(state.opponentScore, 0);
      expect(state.playerStreak, 0);
      expect(state.opponentStreak, 0);
      expect(state.timeRemainingSeconds, 0);
      expect(state.countdownSeconds, 0);
      expect(state.selectedAnswer, isNull);
      expect(state.lastAnswerCorrect, isNull);
      expect(state.matchResult, isNull);
      expect(state.encouragementMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  group('findMatch', () {
    test('sets matchId and isLoading on success', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-123'));

      await readNotifier().findMatch();

      final state = readState();
      expect(state.matchId, 'match-123');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('sets error on failure', () async {
      when(() => mockRepo.findMatch()).thenAnswer(
        (_) async =>
            const Result.failure(ServerFailure(message: 'Connection failed')),
      );

      await readNotifier().findMatch();

      final state = readState();
      expect(state.error, 'Oops! Our server had a hiccup. Let\'s try again!');
      expect(state.isLoading, isFalse);
      expect(state.matchId, isNull);
    });

    test('sets isLoading=true initially', () async {
      final completer = Completer<Result<String>>();
      when(() => mockRepo.findMatch()).thenAnswer((_) => completer.future);

      readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      // Check isLoading is true while request is pending
      expect(readState().isLoading, isTrue);

      completer.complete(const Result.success('match-123'));
      await Future.delayed(Duration.zero);

      expect(readState().isLoading, isFalse);
    });
  });

  group('submitAnswer', () {
    test('does nothing when matchId is null', () async {
      await readNotifier().submitAnswer(5.0);

      verifyNever(
        () => mockRepo.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
        ),
      );
    });

    test('does nothing when currentQuestion is null', () async {
      // Set matchId without setting currentQuestion
      container.read(matchNotifierProvider.notifier).state = readState()
          .copyWith(matchId: 'match-1');

      await readNotifier().submitAnswer(5.0);

      verifyNever(
        () => mockRepo.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
        ),
      );
    });

    test('does nothing when already answered', () async {
      // Set up state with matchId, currentQuestion, and selectedAnswer
      container.read(matchNotifierProvider.notifier).state = readState()
          .copyWith(
            matchId: 'match-1',
            currentQuestion: tQuestion,
            selectedAnswer: 4.0,
          );

      await readNotifier().submitAnswer(5.0);

      verifyNever(
        () => mockRepo.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
        ),
      );
    });

    test('sets selectedAnswer and calls repository', () async {
      // Set up state with matchId and currentQuestion
      container.read(matchNotifierProvider.notifier).state = readState()
          .copyWith(matchId: 'match-1', currentQuestion: tQuestion);

      when(
        () => mockRepo.submitAnswer(
          matchId: any(named: 'matchId'),
          questionId: any(named: 'questionId'),
          answer: any(named: 'answer'),
        ),
      ).thenAnswer((_) async => const Result.success(null));

      await readNotifier().submitAnswer(5.0);

      final state = readState();
      expect(state.selectedAnswer, 5.0);

      verify(
        () => mockRepo.submitAnswer(
          matchId: 'match-1',
          questionId: 'q1',
          answer: 5.0,
        ),
      ).called(1);
    });
  });

  group('leaveMatch', () {
    test('resets state and disconnects', () async {
      // Set up initial state
      container.read(matchNotifierProvider.notifier).state = readState()
          .copyWith(matchId: 'match-1', opponent: tOpponent, playerScore: 50);

      when(
        () => mockRepo.disconnect(),
      ).thenAnswer((_) async => const Result.success(null));

      await readNotifier().leaveMatch();

      final state = readState();
      expect(state.matchId, isNull);
      expect(state.opponent, isNull);
      expect(state.playerScore, 0);
      expect(state.status, MatchStatus.waiting);

      verify(() => mockRepo.disconnect()).called(1);
    });
  });

  group('reset', () {
    test('returns to initial state', () async {
      // Set up initial state
      container.read(matchNotifierProvider.notifier).state = readState()
          .copyWith(
            matchId: 'match-1',
            opponent: tOpponent,
            playerScore: 50,
            currentQuestion: tQuestion,
          );

      readNotifier().reset();

      final state = readState();
      expect(state.matchId, isNull);
      expect(state.opponent, isNull);
      expect(state.currentQuestion, isNull);
      expect(state.playerScore, 0);
      expect(state.status, MatchStatus.waiting);
    });
  });

  group('event handling', () {
    test('processes MatchFoundEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(
        MatchFoundEvent(
          matchId: 'match-1',
          opponent: tOpponent,
          totalQuestions: 10,
        ),
      );

      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.opponent, tOpponent);
      expect(state.totalQuestions, 10);
      expect(state.status, MatchStatus.countdown);
    });

    test('processes CountdownEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(const CountdownEvent(secondsRemaining: 3));
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.countdownSeconds, 3);
      expect(state.status, MatchStatus.countdown);
    });

    test('processes QuestionEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(
        QuestionEvent(
          question: tQuestion,
          questionIndex: 0,
          timeRemainingSeconds: 30,
        ),
      );

      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.currentQuestion, tQuestion);
      expect(state.questionIndex, 0);
      expect(state.timeRemainingSeconds, 30);
      expect(state.status, MatchStatus.inProgress);
    });

    test('processes AnswerResultEvent with correct answer', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(
        const AnswerResultEvent(
          isCorrect: true,
          pointsEarned: 10,
          correctAnswer: 5.0,
        ),
      );

      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.lastAnswerCorrect, isTrue);
      expect(state.encouragementMessage, isNotNull);
    });

    test('processes AnswerResultEvent with incorrect answer', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(
        const AnswerResultEvent(
          isCorrect: false,
          pointsEarned: 0,
          correctAnswer: 5.0,
        ),
      );

      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.lastAnswerCorrect, isFalse);
      expect(state.encouragementMessage, contains('Don\'t worry'));
    });

    test('processes ScoreUpdateEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(
        const ScoreUpdateEvent(
          playerScore: 30,
          opponentScore: 20,
          playerStreak: 3,
          opponentStreak: 2,
        ),
      );

      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.playerScore, 30);
      expect(state.opponentScore, 20);
      expect(state.playerStreak, 3);
      expect(state.opponentStreak, 2);
    });

    test('processes MatchCompleteEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(MatchCompleteEvent(result: tResult));

      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.status, MatchStatus.completed);
      expect(state.matchResult, tResult);
    });

    test('processes OpponentDisconnectEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      eventsController.add(const OpponentDisconnectEvent());
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.status, MatchStatus.disconnected);
      expect(state.encouragementMessage, contains('opponent left'));
    });

    test('processes OpponentReconnectEvent', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      // First disconnect
      eventsController.add(const OpponentDisconnectEvent());
      await Future.delayed(Duration.zero);
      expect(readState().status, MatchStatus.disconnected);

      // Then reconnect
      eventsController.add(const OpponentReconnectEvent());
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.status, MatchStatus.inProgress);
      expect(state.encouragementMessage, contains('opponent is back'));
    });

    test('multiple events update state correctly', () async {
      when(
        () => mockRepo.findMatch(),
      ).thenAnswer((_) async => const Result.success('match-1'));

      await readNotifier().findMatch();
      await Future.delayed(Duration.zero);

      // Emit MatchFoundEvent
      eventsController.add(
        MatchFoundEvent(
          matchId: 'match-1',
          opponent: tOpponent,
          totalQuestions: 2,
        ),
      );
      await Future.delayed(Duration.zero);

      expect(readState().opponent, tOpponent);
      expect(readState().status, MatchStatus.countdown);

      // Emit CountdownEvent
      eventsController.add(const CountdownEvent(secondsRemaining: 1));
      await Future.delayed(Duration.zero);

      expect(readState().countdownSeconds, 1);

      // Emit QuestionEvent
      eventsController.add(
        QuestionEvent(
          question: tQuestion,
          questionIndex: 0,
          timeRemainingSeconds: 30,
        ),
      );
      await Future.delayed(Duration.zero);

      expect(readState().currentQuestion, tQuestion);
      expect(readState().status, MatchStatus.inProgress);

      // Emit ScoreUpdateEvent
      eventsController.add(
        const ScoreUpdateEvent(
          playerScore: 10,
          opponentScore: 0,
          playerStreak: 1,
          opponentStreak: 0,
        ),
      );
      await Future.delayed(Duration.zero);

      final state = readState();
      expect(state.playerScore, 10);
      expect(state.opponentScore, 0);
      expect(state.playerStreak, 1);
    });
  });
}
