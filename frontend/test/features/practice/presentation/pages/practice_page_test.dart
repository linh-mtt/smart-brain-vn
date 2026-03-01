import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/practice/domain/entities/practice_question_entity.dart';
import 'package:smart_math_kids/features/practice/domain/entities/session_feedback_entity.dart';
import 'package:smart_math_kids/features/practice/domain/repositories/practice_repository.dart';
import 'package:smart_math_kids/features/practice/presentation/pages/practice_page.dart';
import 'package:smart_math_kids/features/practice/presentation/providers/practice_providers.dart';

class MockPracticeRepository extends Mock implements PracticeRepository {}

void main() {
  late MockPracticeRepository mockRepo;

  final tQuestions = [
    PracticeQuestionEntity(
      id: 'q1',
      questionText: '2 + 3',
      correctAnswer: 5.0,
      options: ['3', '4', '5', '6'],
      explanation: 'Two plus three',
      topic: 'addition',
      difficultyLevel: 1,
    ),
    PracticeQuestionEntity(
      id: 'q2',
      questionText: '4 + 1',
      correctAnswer: 5.0,
      options: ['3', '4', '5', '6'],
      explanation: 'Four plus one equals five',
      topic: 'addition',
      difficultyLevel: 1,
    ),
  ];

  final tStartData = (
    sessionId: 'sess-1',
    topic: 'addition',
    difficultyStart: 1,
    questions: tQuestions,
  );

  final tFeedbackEntity = SessionFeedbackEntity(
    isCorrect: true,
    correctAnswer: 5.0,
    pointsEarned: 10,
    comboCount: 1,
    comboMultiplier: 1.0,
    maxCombo: 1,
    newDifficulty: 1,
    eloRating: 1000.0,
    streak: 1,
    weakTopics: [],
    sessionProgress: SessionProgressEntity(
      totalQuestions: 2,
      correctCount: 1,
      totalPoints: 10,
      totalTimeMs: 3000,
      accuracy: 50.0,
    ),
  );

  setUp(() {
    mockRepo = MockPracticeRepository();
  });

  Widget buildTestWidget({String topic = 'addition', int questionCount = 5}) {
    return ProviderScope(
      overrides: [practiceRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(
        home: PracticePage(topic: topic, questionCount: questionCount),
      ),
    );
  }

  group('PracticePage', () {
    testWidgets('shows loading indicator when starting', (tester) async {
      // Use a Completer that never resolves to keep the loading state
      final completer = Completer<Result<({String sessionId, String topic, int difficultyStart, List<PracticeQuestionEntity> questions})>>();
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(); // Process microtask that fires startSession

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Starting practice...'), findsOneWidget);
      // Do NOT complete the Completer — avoids flutter_animate pending Timers
    });

    testWidgets('shows question text and answer options after loading', (
      tester,
    ) async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(); // Process microtask
      await tester.pump(); // Process async response
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // Let animations start

      // Check question text is displayed
      expect(find.textContaining('2 + 3'), findsOneWidget);

      // Check answer options are displayed
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('shows progress indicator and score', (tester) async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check progress text
      expect(find.textContaining('Problem 1 of 2'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // Initial score
    });

    testWidgets('shows error state with retry button', (tester) async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer(
        (_) async =>
            const Result.failure(ServerFailure(message: 'Server error')),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error emoji and retry button
      expect(find.text('😕'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('tapping answer calls submitAnswer', (tester) async {
      // Use a larger screen to avoid offscreen issues
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      // Use a Completer that never resolves to prevent _onFeedbackReceived
      // from creating pending Timers (Future.delayed + flutter_animate).
      final submitCompleter = Completer<Result<SessionFeedbackEntity>>();
      when(
        () => mockRepo.submitAnswer(
          sessionId: any(named: 'sessionId'),
          questionId: any(named: 'questionId'),
          topic: any(named: 'topic'),
          difficultyLevel: any(named: 'difficultyLevel'),
          questionText: any(named: 'questionText'),
          correctAnswer: any(named: 'correctAnswer'),
          answer: any(named: 'answer'),
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).thenAnswer((_) => submitCompleter.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll down to make the answer buttons visible
      final scrollable = find.byType(SingleChildScrollView);
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pump();

      // Find and tap the answer '5' (correct answer)
      final answerFinder = find.text('5');
      expect(answerFinder, findsOneWidget);
      await tester.ensureVisible(answerFinder);
      await tester.pump();
      await tester.tap(answerFinder);
      await tester.pump();

      verify(
        () => mockRepo.submitAnswer(
          sessionId: 'sess-1',
          questionId: 'q1',
          topic: 'addition',
          difficultyLevel: 1,
          questionText: '2 + 3',
          correctAnswer: 5.0,
          answer: 5.0,
          timeTakenMs: any(named: 'timeTakenMs'),
        ),
      ).called(1);

      // Flush zero-duration timers created by flutter_animate's _restart
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows topic in app bar', (tester) async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await tester.pumpWidget(buildTestWidget(topic: 'addition'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ADDITION'), findsOneWidget);
    });
  });
}
