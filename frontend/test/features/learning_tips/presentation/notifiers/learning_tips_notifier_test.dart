import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/learning_tip_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/tip_step_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/quiz_question_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/tip_progress_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/repositories/learning_tips_repository.dart';
import 'package:smart_math_kids/features/learning_tips/presentation/notifiers/learning_tips_notifier.dart';
import 'package:smart_math_kids/features/learning_tips/presentation/providers/learning_tips_providers.dart';

class MockLearningTipsRepository extends Mock
    implements LearningTipsRepository {}

void main() {
  late MockLearningTipsRepository mockRepo;
  late ProviderContainer container;

  final tTip = LearningTipEntity(
    id: 'tip_1',
    title: 'Test Tip',
    description: 'Test description',
    category: 'addition',
    icon: '➕',
    difficulty: 1,
    steps: const [
      TipStepEntity(title: 'Step 1', content: 'Content 1', example: 'Ex 1'),
      TipStepEntity(title: 'Step 2', content: 'Content 2', example: 'Ex 2'),
      TipStepEntity(title: 'Step 3', content: 'Content 3', example: 'Ex 3'),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'q1',
        question: 'Q1?',
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation: 'Exp 1',
      ),
      QuizQuestionEntity(
        id: 'q2',
        question: 'Q2?',
        options: ['E', 'F', 'G', 'H'],
        correctIndex: 2,
        explanation: 'Exp 2',
      ),
    ],
    animationAsset: 'assets/test.json',
    color: '#FF6B6B',
  );

  final tTip2 = LearningTipEntity(
    id: 'tip_2',
    title: 'Test Tip 2',
    description: 'Test description 2',
    category: 'multiplication',
    icon: '✖️',
    difficulty: 2,
    steps: const [
      TipStepEntity(title: 'Step 1', content: 'Content', example: 'Ex'),
    ],
    quizQuestions: const [
      QuizQuestionEntity(
        id: 'q3',
        question: 'Q3?',
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 1,
        explanation: 'Exp 3',
      ),
    ],
    animationAsset: 'assets/test2.json',
    color: '#4ECDC4',
  );

  final tProgress = TipProgressEntity(
    tipId: 'tip_1',
    isCompleted: true,
    quizScore: 2,
    quizTotal: 3,
  );

  setUp(() {
    mockRepo = MockLearningTipsRepository();
    container = ProviderContainer(
      overrides: [learningTipsRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  LearningTipsListState readListState() =>
      container.read(learningTipsListProvider);
  LearningTipsListNotifier readListNotifier() =>
      container.read(learningTipsListProvider.notifier);
  TipDetailState readDetailState() => container.read(tipDetailProvider);
  TipDetailNotifier readDetailNotifier() =>
      container.read(tipDetailProvider.notifier);

  group('LearningTipsListNotifier', () {
    group('initial state', () {
      test('has correct defaults', () {
        final state = readListState();
        expect(state.tips, isEmpty);
        expect(state.progressMap, isEmpty);
        expect(state.selectedCategory, isNull);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });
    });

    group('loadTips', () {
      test('success: loads tips and progress', () async {
        when(
          () => mockRepo.getAllTips(),
        ).thenAnswer((_) async => Result.success([tTip, tTip2]));
        when(
          () => mockRepo.getAllProgress(),
        ).thenAnswer((_) async => Result.success([tProgress]));

        await readListNotifier().loadTips();
        // Add small delay for async fold to complete
        await Future.delayed(const Duration(milliseconds: 100));

        final state = readListState();
        expect(state.tips.length, 2);
        expect(state.tips[0].id, 'tip_1');
        expect(state.tips[1].id, 'tip_2');
        expect(state.progressMap['tip_1'], tProgress);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('failure on getAllTips: shows error', () async {
        when(() => mockRepo.getAllTips()).thenAnswer(
          (_) async => Result.failure(CacheFailure(message: 'Cache error')),
        );

        await readListNotifier().loadTips();
        await Future.delayed(const Duration(milliseconds: 100));

        final state = readListState();
        expect(state.error, isNotNull);
        expect(state.tips, isEmpty);
        expect(state.isLoading, isFalse);
      });

      test(
        'success tips but failure on progress: shows tips without progress',
        () async {
          when(
            () => mockRepo.getAllTips(),
          ).thenAnswer((_) async => Result.success([tTip]));
          when(() => mockRepo.getAllProgress()).thenAnswer(
            (_) async =>
                Result.failure(CacheFailure(message: 'Progress error')),
          );

          await readListNotifier().loadTips();
          await Future.delayed(const Duration(milliseconds: 100));

          final state = readListState();
          expect(state.tips.length, 1);
          expect(state.tips[0].id, 'tip_1');
          expect(state.progressMap, isEmpty);
          expect(state.isLoading, isFalse);
        },
      );
    });

    group('filterByCategory', () {
      test('filters tips by category', () async {
        when(
          () => mockRepo.getAllTips(),
        ).thenAnswer((_) async => Result.success([tTip, tTip2]));
        when(
          () => mockRepo.getAllProgress(),
        ).thenAnswer((_) async => Result.success([]));

        await readListNotifier().loadTips();
        await Future.delayed(const Duration(milliseconds: 100));
        readListNotifier().filterByCategory('addition');

        final state = readListState();
        expect(state.filteredTips.length, 1);
        expect(state.filteredTips[0].category, 'addition');
      });

      test('filterByCategory(null) shows all tips', () async {
        when(
          () => mockRepo.getAllTips(),
        ).thenAnswer((_) async => Result.success([tTip, tTip2]));
        when(
          () => mockRepo.getAllProgress(),
        ).thenAnswer((_) async => Result.success([]));

        await readListNotifier().loadTips();
        await Future.delayed(const Duration(milliseconds: 100));
        readListNotifier().filterByCategory('addition');
        readListNotifier().filterByCategory(null);

        final state = readListState();
        expect(state.selectedCategory, isNull);
        expect(state.filteredTips.length, 2);
      });
    });

    group('refreshProgress', () {
      test('updates progress map', () async {
        when(
          () => mockRepo.getAllTips(),
        ).thenAnswer((_) async => Result.success([tTip, tTip2]));
        when(
          () => mockRepo.getAllProgress(),
        ).thenAnswer((_) async => Result.success([tProgress]));

        await readListNotifier().loadTips();
        await Future.delayed(const Duration(milliseconds: 100));

        final tProgress2 = TipProgressEntity(
          tipId: 'tip_2',
          isCompleted: false,
          quizScore: 1,
          quizTotal: 2,
        );

        when(
          () => mockRepo.getAllProgress(),
        ).thenAnswer((_) async => Result.success([tProgress, tProgress2]));

        await readListNotifier().refreshProgress();
        await Future.delayed(const Duration(milliseconds: 100));

        final state = readListState();
        expect(state.progressMap.length, 2);
        expect(state.progressMap['tip_1'], tProgress);
        expect(state.progressMap['tip_2'], tProgress2);
      });
    });

    group('completedCount', () {
      test('returns correct count of completed tips', () async {
        when(
          () => mockRepo.getAllTips(),
        ).thenAnswer((_) async => Result.success([tTip, tTip2]));
        when(() => mockRepo.getAllProgress()).thenAnswer(
          (_) async => Result.success([
            tProgress, // completed
            TipProgressEntity(tipId: 'tip_2', isCompleted: false),
          ]),
        );

        await readListNotifier().loadTips();
        await Future.delayed(const Duration(milliseconds: 100));

        final state = readListState();
        expect(state.completedCount, 1);
      });
    });
  });

  group('TipDetailNotifier', () {
    group('initial state', () {
      test('has correct defaults', () {
        final state = readDetailState();
        expect(state.tip, isNull);
        expect(state.currentStepIndex, 0);
        expect(state.isQuizMode, isFalse);
        expect(state.currentQuizIndex, 0);
        expect(state.selectedAnswerIndex, isNull);
        expect(state.quizAnswers, isEmpty);
        expect(state.quizCompleted, isFalse);
        expect(state.correctCount, 0);
        expect(state.showExplanation, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });
    });

    group('loadTip', () {
      test('success: loads tip and resets state', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');

        final state = readDetailState();
        expect(state.tip, tTip);
        expect(state.currentStepIndex, 0);
        expect(state.isQuizMode, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('failure: shows error', () async {
        when(() => mockRepo.getTipById('tip_1')).thenAnswer(
          (_) async => Result.failure(CacheFailure(message: 'Tip not found')),
        );

        await readDetailNotifier().loadTip('tip_1');

        final state = readDetailState();
        expect(state.tip, isNull);
        expect(state.error, isNotNull);
        expect(state.isLoading, isFalse);
      });
    });

    group('nextStep', () {
      test('advances to next step', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().nextStep();

        final state = readDetailState();
        expect(state.currentStepIndex, 1);
      });

      test('advances step index correctly multiple times', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().nextStep();
        readDetailNotifier().nextStep();

        final state = readDetailState();
        expect(state.currentStepIndex, 2);
      });

      test('does not advance beyond last step', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().nextStep();
        readDetailNotifier().nextStep();
        readDetailNotifier().nextStep();

        final state = readDetailState();
        expect(state.currentStepIndex, 2);
      });

      test('does nothing if tip is null', () {
        readDetailNotifier().nextStep();
        final state = readDetailState();
        expect(state.currentStepIndex, 0);
      });
    });

    group('previousStep', () {
      test('goes to previous step', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().nextStep();
        readDetailNotifier().previousStep();

        final state = readDetailState();
        expect(state.currentStepIndex, 0);
      });

      test('does not go below 0', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().previousStep();

        final state = readDetailState();
        expect(state.currentStepIndex, 0);
      });
    });

    group('startQuiz', () {
      test('transitions to quiz mode with correct initial state', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();

        final state = readDetailState();
        expect(state.isQuizMode, isTrue);
        expect(state.currentQuizIndex, 0);
        expect(state.quizAnswers, isEmpty);
        expect(state.correctCount, 0);
        expect(state.quizCompleted, isFalse);
      });
    });

    group('selectAnswer', () {
      test('selects answer option', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(1);

        final state = readDetailState();
        expect(state.selectedAnswerIndex, 1);
      });

      test('does not select when showing explanation', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(0);
        readDetailNotifier().submitAnswer();

        // At this point, showExplanation is true and selectedAnswerIndex is null
        // Trying to select should not work because showExplanation is true
        final stateBefore = readDetailState();
        expect(stateBefore.showExplanation, isTrue);
        expect(stateBefore.selectedAnswerIndex, isNull);

        readDetailNotifier().selectAnswer(2);
        final stateAfter = readDetailState();
        expect(stateAfter.selectedAnswerIndex, isNull); // Still null
      });

      test('does not select when quiz is completed', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(0);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();
        readDetailNotifier().selectAnswer(1);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();

        // Now quiz should be completed, selectedAnswerIndex resets to null
        // Try to select answer - should be blocked
        readDetailNotifier().selectAnswer(3);

        final state = readDetailState();
        expect(state.quizCompleted, isTrue);
        expect(state.selectedAnswerIndex, isNull); // Stays null
      });
    });

    group('submitAnswer', () {
      test('correct answer increments correctCount', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(0); // correct for q1

        readDetailNotifier().submitAnswer();

        final state = readDetailState();
        expect(state.correctCount, 1);
        expect(state.showExplanation, isTrue);
      });

      test('wrong answer does not increment correctCount', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(1); // wrong for q1

        readDetailNotifier().submitAnswer();

        final state = readDetailState();
        expect(state.correctCount, 0);
        expect(state.showExplanation, isTrue);
      });

      test('does nothing when selectedAnswerIndex is null', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().submitAnswer();

        final state = readDetailState();
        expect(state.correctCount, 0);
        expect(state.showExplanation, isFalse);
      });

      test('stores answer in quizAnswers map', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(2);
        readDetailNotifier().submitAnswer();

        final state = readDetailState();
        expect(state.quizAnswers[0], 2);
      });
    });

    group('nextQuestion', () {
      test('advances to next question', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(0);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();

        final state = readDetailState();
        expect(state.currentQuizIndex, 1);
        expect(state.showExplanation, isFalse);
        expect(state.selectedAnswerIndex, isNull);
      });

      test('completes quiz on last question', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(0);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();
        readDetailNotifier().selectAnswer(2);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();

        final state = readDetailState();
        expect(state.quizCompleted, isTrue);
        expect(state.showExplanation, isFalse);
      });
    });

    group('completeQuiz', () {
      test('calls markTipCompleted with correct arguments', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));
        when(
          () => mockRepo.markTipCompleted(
            any(),
            quizScore: any(named: 'quizScore'),
            quizTotal: any(named: 'quizTotal'),
          ),
        ).thenAnswer((_) async => const Result.success(null));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().startQuiz();
        readDetailNotifier().selectAnswer(0);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();
        readDetailNotifier().selectAnswer(2);
        readDetailNotifier().submitAnswer();
        readDetailNotifier().nextQuestion();

        await readDetailNotifier().completeQuiz();

        verify(
          () => mockRepo.markTipCompleted('tip_1', quizScore: 2, quizTotal: 2),
        ).called(1);
      });

      test('does nothing if tip is null', () async {
        when(
          () => mockRepo.markTipCompleted(
            any(),
            quizScore: any(named: 'quizScore'),
            quizTotal: any(named: 'quizTotal'),
          ),
        ).thenAnswer((_) async => const Result.success(null));

        await readDetailNotifier().completeQuiz();

        verifyNever(
          () => mockRepo.markTipCompleted(
            any(),
            quizScore: any(named: 'quizScore'),
            quizTotal: any(named: 'quizTotal'),
          ),
        );
      });
    });

    group('reset', () {
      test('resets to initial state', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().nextStep();
        readDetailNotifier().startQuiz();

        readDetailNotifier().reset();

        final state = readDetailState();
        expect(state.tip, isNull);
        expect(state.currentStepIndex, 0);
        expect(state.isQuizMode, isFalse);
        expect(state.currentQuizIndex, 0);
        expect(state.selectedAnswerIndex, isNull);
      });
    });

    group('getters', () {
      test('totalSteps returns correct count', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');

        final state = readDetailState();
        expect(state.totalSteps, 3);
      });

      test('totalQuestions returns correct count', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');

        final state = readDetailState();
        expect(state.totalQuestions, 2);
      });

      test('isLastStep returns true on last step', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');
        readDetailNotifier().nextStep();
        readDetailNotifier().nextStep();

        final state = readDetailState();
        expect(state.isLastStep, isTrue);
      });

      test('isLastStep returns false on non-last step', () async {
        when(
          () => mockRepo.getTipById('tip_1'),
        ).thenAnswer((_) async => Result.success(tTip));

        await readDetailNotifier().loadTip('tip_1');

        final state = readDetailState();
        expect(state.isLastStep, isFalse);
      });
    });
  });
}
