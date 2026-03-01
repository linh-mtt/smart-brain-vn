import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/practice/data/models/practice_question_model.dart';
import 'package:smart_math_kids/features/practice/data/models/session_feedback_model.dart';
import 'package:smart_math_kids/features/practice/domain/entities/practice_question_entity.dart';
import 'package:smart_math_kids/features/practice/domain/entities/session_feedback_entity.dart';
import 'package:smart_math_kids/features/practice/domain/repositories/practice_repository.dart';
import 'package:smart_math_kids/features/practice/presentation/notifiers/practice_notifier.dart';
import 'package:smart_math_kids/features/practice/presentation/providers/practice_providers.dart';

class MockPracticeRepository extends Mock implements PracticeRepository {}


void main() {
  late MockPracticeRepository mockRepo;
  late ProviderContainer container;

  final tQuestionEntity = PracticeQuestionEntity(
    id: 'q1',
    questionText: '2 + 3',
    correctAnswer: 5.0,
    options: ['3', '4', '5', '6'],
    explanation: 'Two plus three equals five',
    topic: 'addition',
    difficultyLevel: 1,
  );

  final tQuestionEntity2 = PracticeQuestionEntity(
    id: 'q2',
    questionText: '4 + 1',
    correctAnswer: 5.0,
    options: ['3', '4', '5', '6'],
    explanation: 'Four plus one equals five',
    topic: 'addition',
    difficultyLevel: 1,
  );

  final tStartData = (
    sessionId: 'sess-1',
    topic: 'addition',
    difficultyStart: 1,
    questions: [tQuestionEntity, tQuestionEntity2],
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
    container = ProviderContainer(
      overrides: [practiceRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  PracticeSessionState readState() => container.read(practiceSessionProvider);
  PracticeSessionNotifier readNotifier() =>
      container.read(practiceSessionProvider.notifier);

  group('initial state', () {
    test('has correct defaults', () {
      final state = readState();
      expect(state.sessionId, isNull);
      expect(state.topic, '');
      expect(state.questions, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.score, 0);
      expect(state.comboCount, 0);
      expect(state.comboMultiplier, 1.0);
      expect(state.maxCombo, 0);
      expect(state.correctCount, 0);
      expect(state.feedback, isEmpty);
      expect(state.currentFeedback, isNull);
      expect(state.isCompleted, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.error, isNull);
      expect(state.currentQuestion, isNull);
      expect(state.accuracy, 0.0);
    });
  });

  group('startSession', () {
    test('populates state on success', () async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await readNotifier().startSession('addition', questionCount: 5);

      final state = readState();
      expect(state.sessionId, 'sess-1');
      expect(state.topic, 'addition');
      expect(state.questions.length, 2);
      expect(state.questions.first.id, 'q1');
      expect(state.difficultyStart, 1);
      expect(state.feedback.length, 2);
      expect(state.feedback.every((f) => f == null), isTrue);
      expect(state.isLoading, isFalse);
      expect(state.questionStartTime, isNotNull);
    });

    test('sets error on failure', () async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer(
        (_) async =>
            const Result.failure(ServerFailure(message: 'Server down')),
      );

      await readNotifier().startSession('addition');

      final state = readState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.questions, isEmpty);
    });
  });

  group('submitAnswer', () {
    test('updates state on success', () async {
      // First start a session
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

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
      ).thenAnswer((_) async => Result.success(tFeedbackEntity));

      await readNotifier().startSession('addition');
      await readNotifier().submitAnswer(5.0);

      final state = readState();
      expect(state.score, 10);
      expect(state.comboCount, 1);
      expect(state.comboMultiplier, 1.0);
      expect(state.maxCombo, 1);
      expect(state.correctCount, 1);
      expect(state.isSubmitting, isFalse);
      expect(state.feedback[0], isNotNull);
      expect(state.feedback[0]!.isCorrect, isTrue);
      expect(state.currentFeedback, isNotNull);
    });

    test('does nothing when no current question', () async {
      // Don't start a session
      await readNotifier().submitAnswer(5.0);

      verifyNever(
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
      );
    });
  });

  group('nextQuestion', () {
    test('advances currentIndex', () async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await readNotifier().startSession('addition');
      expect(readState().currentIndex, 0);

      readNotifier().nextQuestion();

      final state = readState();
      expect(state.currentIndex, 1);
      expect(state.questionStartTime, isNotNull);
      expect(state.isCompleted, isFalse);
    });

    test('marks isCompleted on last question', () async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await readNotifier().startSession('addition');

      // Move to question 2 (index 1, last)
      readNotifier().nextQuestion();
      expect(readState().isCompleted, isFalse);

      // Try to move past last question
      readNotifier().nextQuestion();
      expect(readState().isCompleted, isTrue);
    });
  });

  group('reset', () {
    test('returns to initial state', () async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

      await readNotifier().startSession('addition');
      expect(readState().questions.isNotEmpty, isTrue);

      readNotifier().reset();

      final state = readState();
      expect(state.sessionId, isNull);
      expect(state.questions, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.score, 0);
      expect(state.isCompleted, isFalse);
    });
  });

  group('accuracy', () {
    test('returns 0 when no questions answered', () {
      expect(readState().accuracy, 0.0);
    });

    test('computes correctly after answers', () async {
      when(
        () => mockRepo.startSession(
          topic: any(named: 'topic'),
          questionCount: any(named: 'questionCount'),
        ),
      ).thenAnswer((_) async => Result.success(tStartData));

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
      ).thenAnswer((_) async => Result.success(tFeedbackEntity));

      await readNotifier().startSession('addition');
      await readNotifier().submitAnswer(5.0);

      // accuracy = correctCount / currentIndex * 100
      // After submitting question 0: correctCount=1, but currentIndex is still 0
      // So accuracy uses the sessionProgress.correctCount/currentIndex
      // Actually accuracy getter: currentIndex > 0 ? (correctCount / currentIndex) * 100 : 0
      // currentIndex is still 0 because we haven't called nextQuestion yet
      // So accuracy is 0

      readNotifier().nextQuestion();
      // Now currentIndex=1, correctCount=1 → accuracy=100
      expect(readState().accuracy, 100.0);
    });
  });
}
