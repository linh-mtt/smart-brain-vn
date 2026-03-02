
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/learning_tip_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/tip_step_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/quiz_question_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/entities/tip_progress_entity.dart';
import 'package:smart_math_kids/features/learning_tips/domain/repositories/learning_tips_repository.dart';
import 'package:smart_math_kids/features/learning_tips/presentation/pages/learning_tips_page.dart';
import 'package:smart_math_kids/features/learning_tips/presentation/providers/learning_tips_providers.dart';

// Mock Repository
class MockLearningTipsRepository extends Mock
    implements LearningTipsRepository {}

void main() {
  late MockLearningTipsRepository mockRepo;

  // Test fixtures
  final tTips = [
    LearningTipEntity(
      id: 'tip_1',
      title: 'Adding 9 Trick',
      description: 'Add 10 then subtract 1',
      category: 'addition',
      icon: '➕',
      difficulty: 1,
      steps: const [
        TipStepEntity(title: 'Step 1', content: 'Content', example: 'Ex'),
      ],
      quizQuestions: const [
        QuizQuestionEntity(
          id: 'q1',
          question: 'Q?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Exp',
        ),
      ],
      animationAsset: 'assets/animations/tip_addition.json',
      color: '#FF6B6B',
    ),
    LearningTipEntity(
      id: 'tip_2',
      title: 'Multiply by 5',
      description: 'Multiply by 10 then halve',
      category: 'multiplication',
      icon: '✖️',
      difficulty: 2,
      steps: const [
        TipStepEntity(title: 'Step 1', content: 'Content', example: 'Ex'),
      ],
      quizQuestions: const [
        QuizQuestionEntity(
          id: 'q2',
          question: 'Q?',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Exp',
        ),
      ],
      animationAsset: 'assets/animations/tip_multiplication.json',
      color: '#4ECDC4',
    ),
  ];

  final tProgress = [
    TipProgressEntity(
      tipId: 'tip_1',
      isCompleted: true,
      quizScore: 3,
      quizTotal: 3,
    ),
  ];

  setUp(() {
    mockRepo = MockLearningTipsRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [learningTipsRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: LearningTipsPage()),
    );
  }

  group('LearningTipsPage Widget Tests', () {
    testWidgets('page initializes and renders without errors', (WidgetTester tester) async {
      // Setup: Mock both methods immediately
      when(() => mockRepo.getAllTips())
          .thenAnswer((_) async => Result.success([]));
      when(() => mockRepo.getAllProgress())
          .thenAnswer((_) async => Result.success([]));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Page renders without throwing errors
      expect(find.byType(LearningTipsPage), findsOneWidget);
    });

    testWidgets('shows tip cards after loading completes', (
      WidgetTester tester,
    ) async {
      // Setup: Mock both getAllTips and getAllProgress
      when(
        () => mockRepo.getAllTips(),
      ).thenAnswer((_) async => Result.success(tTips));
      when(
        () => mockRepo.getAllProgress(),
      ).thenAnswer((_) async => Result.success(tProgress));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Both tip titles and descriptions appear
      expect(find.text('Adding 9 Trick'), findsOneWidget);
      expect(find.text('Multiply by 5'), findsOneWidget);
      expect(find.text('Add 10 then subtract 1'), findsOneWidget);
      expect(find.text('Multiply by 10 then halve'), findsOneWidget);
    });

    testWidgets('shows progress badge with completion count', (
      WidgetTester tester,
    ) async {
      // Setup: Mock with progress data showing 1 completed tip out of 2
      when(
        () => mockRepo.getAllTips(),
      ).thenAnswer((_) async => Result.success(tTips));
      when(
        () => mockRepo.getAllProgress(),
      ).thenAnswer((_) async => Result.success(tProgress));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Progress badge shows "1/2"
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('shows completed tip card with score badge', (
      WidgetTester tester,
    ) async {
      // Setup: Mock with progress data
      when(
        () => mockRepo.getAllTips(),
      ).thenAnswer((_) async => Result.success(tTips));
      when(
        () => mockRepo.getAllProgress(),
      ).thenAnswer((_) async => Result.success(tProgress));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Completed tip shows score badge "Score: 3/3"
      expect(find.text('Score: 3/3'), findsOneWidget);
    });

    testWidgets('shows error state with retry button on failure', (
      WidgetTester tester,
    ) async {
      // Setup: Mock getAllTips to return a failure
      when(() => mockRepo.getAllTips()).thenAnswer(
        (_) async => Result.failure(CacheFailure(message: 'Storage error')),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Error message and retry button appear
      expect(find.text('Oops! Something went wrong.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('displays category filter chips', (WidgetTester tester) async {
      // Setup: Mock with success response
      when(
        () => mockRepo.getAllTips(),
      ).thenAnswer((_) async => Result.success(tTips));
      when(
        () => mockRepo.getAllProgress(),
      ).thenAnswer((_) async => Result.success([]));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Category filter chips are displayed
      expect(find.text('All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    });

    testWidgets('filters tips by category when chip is tapped', (
      WidgetTester tester,
    ) async {
      // Setup: Mock with both tips (addition and multiplication categories)
      when(
        () => mockRepo.getAllTips(),
      ).thenAnswer((_) async => Result.success(tTips));
      when(
        () => mockRepo.getAllProgress(),
      ).thenAnswer((_) async => Result.success(tProgress));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Both tips should be visible initially
      expect(find.text('Adding 9 Trick'), findsOneWidget);
      expect(find.text('Multiply by 5'), findsOneWidget);

      // Tap multiplication category chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Multiplication ✖️'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify: Only multiplication tip is visible, addition tip is hidden
      expect(find.text('Multiply by 5'), findsOneWidget);
      expect(find.text('Adding 9 Trick'), findsNothing);
    });
  });
}
