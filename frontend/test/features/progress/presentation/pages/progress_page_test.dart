import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/progress/domain/entities/chart_data_point_entity.dart';
import 'package:smart_math_kids/features/progress/domain/entities/progress_summary_entity.dart';
import 'package:smart_math_kids/features/progress/domain/entities/topic_progress_entity.dart';
import 'package:smart_math_kids/features/progress/domain/entities/weekly_comparison_entity.dart';
import 'package:smart_math_kids/features/progress/domain/repositories/progress_repository.dart';
import 'package:smart_math_kids/features/progress/presentation/pages/progress_page.dart';
import 'package:smart_math_kids/features/progress/presentation/providers/progress_providers.dart';

class MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late MockProgressRepository mockRepo;

  // ─── Test Data ───────────────────────────────────────────────────────

  const tSummary = ProgressSummaryEntity(
    totalPoints: 500,
    currentStreak: 3,
    longestStreak: 7,
    totalExercises: 50,
    accuracyRate: 85.0,
    level: 5,
    xpToNextLevel: 200,
  );

  const tTopicProgress = [
    TopicProgressEntity(
      topic: 'addition',
      masteryScore: 75.0,
      totalAnswered: 30,
      correctCount: 22,
      recentScores: [true, true, false, true, true],
    ),
    TopicProgressEntity(
      topic: 'subtraction',
      masteryScore: 60.0,
      totalAnswered: 20,
      correctCount: 12,
      recentScores: [true, false, true, false, true],
    ),
  ];

  final tAccuracyHistory = [
    ChartDataPointEntity(date: DateTime(2025, 1, 1), value: 80.0),
    ChartDataPointEntity(date: DateTime(2025, 1, 2), value: 85.0),
    ChartDataPointEntity(date: DateTime(2025, 1, 3), value: 90.0),
  ];

  final tSpeedHistory = [
    ChartDataPointEntity(date: DateTime(2025, 1, 1), value: 5.2),
    ChartDataPointEntity(date: DateTime(2025, 1, 2), value: 4.8),
    ChartDataPointEntity(date: DateTime(2025, 1, 3), value: 4.3),
  ];

  const tWeeklyComparison = WeeklyComparisonEntity(
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    thisWeek: [10, 15, 20, 12, 18, 25, 8],
    lastWeek: [8, 12, 15, 10, 14, 20, 6],
    thisWeekAverage: 15.4,
    lastWeekAverage: 12.1,
    improvementPercent: 27.3,
  );

  setUp(() {
    mockRepo = MockProgressRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: Scaffold(body: ProgressPage())),
    );
  }

  void stubSuccessfulLoad() {
    when(
      () => mockRepo.getProgressSummary(),
    ).thenAnswer((_) async => const Result.success(tSummary));
    when(
      () => mockRepo.getAllTopicProgress(),
    ).thenAnswer((_) async => const Result.success(tTopicProgress));
    when(
      () => mockRepo.getAccuracyHistory(),
    ).thenAnswer((_) async => Result.success(tAccuracyHistory));
    when(
      () => mockRepo.getSpeedHistory(),
    ).thenAnswer((_) async => Result.success(tSpeedHistory));
    when(
      () => mockRepo.getWeeklyComparison(),
    ).thenAnswer((_) async => const Result.success(tWeeklyComparison));
  }

  void stubFailedLoad() {
    when(() => mockRepo.getProgressSummary()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Server error')),
    );
    when(() => mockRepo.getAllTopicProgress()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Server error')),
    );
    when(() => mockRepo.getAccuracyHistory()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Server error')),
    );
    when(() => mockRepo.getSpeedHistory()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Server error')),
    );
    when(() => mockRepo.getWeeklyComparison()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Server error')),
    );
  }

  /// Pumps enough frames for async data to load and animations to start,
  /// without waiting for flutter_animate animations to fully settle.
  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    await tester.pump(); // Process post-frame callback (triggers loadProgress)
    await tester.pump(); // Process async response
    await tester.pump(
      const Duration(milliseconds: 600),
    ); // Let animations start
  }

  // ─── Loading State ───────────────────────────────────────────────────

  group('loading state', () {
    testWidgets('shows loading indicator initially', (tester) async {
      // Use Completers that never resolve to keep the loading state active
      // and avoid flutter_animate pending timer issues.
      final summaryCompleter = Completer<Result<ProgressSummaryEntity>>();
      final topicCompleter = Completer<Result<List<TopicProgressEntity>>>();

      when(
        () => mockRepo.getProgressSummary(),
      ).thenAnswer((_) => summaryCompleter.future);
      when(
        () => mockRepo.getAllTopicProgress(),
      ).thenAnswer((_) => topicCompleter.future);
      // Chart data won't be called until main data loads, but stub anyway
      when(
        () => mockRepo.getAccuracyHistory(),
      ).thenAnswer((_) async => Result.success(tAccuracyHistory));
      when(
        () => mockRepo.getSpeedHistory(),
      ).thenAnswer((_) async => Result.success(tSpeedHistory));
      when(
        () => mockRepo.getWeeklyComparison(),
      ).thenAnswer((_) async => const Result.success(tWeeklyComparison));

      await tester.pumpWidget(buildWidget());
      await tester.pump(); // Trigger post-frame callback

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Flush flutter_animate zero-duration timers to avoid 'Timer still pending' error
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });
  });

  // ─── Error State ─────────────────────────────────────────────────────

  group('error state', () {
    testWidgets('shows error message and retry button', (tester) async {
      stubFailedLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('😕'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('retry button triggers refresh', (tester) async {
      stubFailedLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      // Now stub success for retry
      stubSuccessfulLoad();

      await tester.tap(find.text('Try Again'));
      await pumpUntilLoaded(tester);

      // Should show data after retry
      expect(find.text('Your Progress 📈'), findsOneWidget);
      verify(() => mockRepo.getProgressSummary()).called(2); // Initial + retry
    });
  });

  // ─── Success State ───────────────────────────────────────────────────

  group('success state', () {
    testWidgets('displays streak card', (tester) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('3 Days'), findsOneWidget);
    });

    testWidgets('displays stats overview tiles', (tester) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Overall Stats'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Accuracy'), findsAtLeastNWidgets(1));
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('7'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays topic mastery cards', (tester) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Topic Mastery'), findsOneWidget);
      expect(find.text('Addition'), findsOneWidget);
      expect(find.text('Subtraction'), findsOneWidget);
    });

    testWidgets('displays page title', (tester) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Your Progress 📈'), findsOneWidget);
    });

    testWidgets('displays accuracy trend section when data available', (
      tester,
    ) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Accuracy Trend'), findsOneWidget);
    });

    testWidgets('displays speed trend section when data available', (
      tester,
    ) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Speed Trend'), findsOneWidget);
    });

    testWidgets('displays weekly comparison section when data available', (
      tester,
    ) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Weekly Comparison'), findsOneWidget);
    });

    testWidgets('displays skill breakdown section when data available', (
      tester,
    ) async {
      stubSuccessfulLoad();

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      expect(find.text('Skill Breakdown'), findsOneWidget);
    });
  });

  // ─── Chart Data Failure ──────────────────────────────────────────────

  group('chart data failure', () {
    testWidgets('still shows main data when chart data fails', (tester) async {
      when(
        () => mockRepo.getProgressSummary(),
      ).thenAnswer((_) async => const Result.success(tSummary));
      when(
        () => mockRepo.getAllTopicProgress(),
      ).thenAnswer((_) async => const Result.success(tTopicProgress));
      when(() => mockRepo.getAccuracyHistory()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );
      when(() => mockRepo.getSpeedHistory()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );
      when(() => mockRepo.getWeeklyComparison()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );

      await tester.pumpWidget(buildWidget());
      await pumpUntilLoaded(tester);

      // Main data should still display
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('3 Days'), findsOneWidget);
      expect(find.text('Overall Stats'), findsOneWidget);
      expect(find.text('Topic Mastery'), findsOneWidget);

      // Charts should not be present
      expect(find.text('Accuracy Trend'), findsNothing);
      expect(find.text('Speed Trend'), findsNothing);
      expect(find.text('Weekly Comparison'), findsNothing);
    });
  });
}
