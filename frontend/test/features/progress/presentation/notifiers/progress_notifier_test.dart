import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/progress/domain/entities/chart_data_point_entity.dart';
import 'package:smart_math_kids/features/progress/domain/entities/progress_summary_entity.dart';
import 'package:smart_math_kids/features/progress/domain/entities/topic_progress_entity.dart';
import 'package:smart_math_kids/features/progress/domain/entities/weekly_comparison_entity.dart';
import 'package:smart_math_kids/features/progress/domain/repositories/progress_repository.dart';
import 'package:smart_math_kids/features/progress/presentation/notifiers/progress_notifier.dart';
import 'package:smart_math_kids/features/progress/presentation/providers/progress_providers.dart';

class MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late MockProgressRepository mockRepo;
  late ProviderContainer container;

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
    container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ProgressState readState() => container.read(progressNotifierProvider);
  ProgressNotifier readNotifier() =>
      container.read(progressNotifierProvider.notifier);

  /// Sets up mock repository to return success for all main data calls.
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

  /// Sets up mock repository to return failure for all main data calls.
  void stubFailedLoad() {
    when(() => mockRepo.getProgressSummary()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Error')),
    );
    when(() => mockRepo.getAllTopicProgress()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Error')),
    );
    when(() => mockRepo.getAccuracyHistory()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Error')),
    );
    when(() => mockRepo.getSpeedHistory()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Error')),
    );
    when(() => mockRepo.getWeeklyComparison()).thenAnswer(
      (_) async => const Result.failure(ServerFailure(message: 'Error')),
    );
  }

  // ─── Initial State ───────────────────────────────────────────────────

  group('initial state', () {
    test('has correct defaults', () {
      final state = readState();
      expect(state.summary, isNull);
      expect(state.topicProgress, isEmpty);
      expect(state.accuracyHistory, isEmpty);
      expect(state.speedHistory, isEmpty);
      expect(state.weeklyComparison, isNull);
      expect(state.isLoading, false);
      expect(state.isLoadingCharts, false);
      expect(state.error, isNull);
      expect(state.hasData, false);
      expect(state.hasChartData, false);
    });
  });

  // ─── loadProgress ────────────────────────────────────────────────────

  group('loadProgress', () {
    test('sets isLoading true, then loads summary and topics', () async {
      stubSuccessfulLoad();

      await readNotifier().loadProgress();

      final state = readState();
      expect(state.isLoading, false);
      expect(state.hasData, true);
      expect(state.summary, tSummary);
      expect(state.topicProgress, tTopicProgress);
      expect(state.error, isNull);
      verify(() => mockRepo.getProgressSummary()).called(1);
      verify(() => mockRepo.getAllTopicProgress()).called(1);
    });

    test('loads chart data after main data', () async {
      stubSuccessfulLoad();

      await readNotifier().loadProgress();
      // Allow unawaited chart loading to complete
      await Future<void>.delayed(Duration.zero);

      final state = readState();
      expect(state.hasChartData, true);
      expect(state.accuracyHistory.length, 3);
      expect(state.speedHistory.length, 3);
      expect(state.weeklyComparison, tWeeklyComparison);
      expect(state.isLoadingCharts, false);
    });

    test('sets error when summary fails', () async {
      when(() => mockRepo.getProgressSummary()).thenAnswer(
        (_) async =>
            const Result.failure(ServerFailure(message: 'Server error')),
      );
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

      await readNotifier().loadProgress();

      final state = readState();
      expect(state.error, isNotNull);
      expect(state.summary, isNull);
      expect(state.hasData, false);
    });

    test('sets error when topic progress fails', () async {
      when(
        () => mockRepo.getProgressSummary(),
      ).thenAnswer((_) async => const Result.success(tSummary));
      when(() => mockRepo.getAllTopicProgress()).thenAnswer(
        (_) async =>
            const Result.failure(ServerFailure(message: 'Topic error')),
      );
      when(
        () => mockRepo.getAccuracyHistory(),
      ).thenAnswer((_) async => Result.success(tAccuracyHistory));
      when(
        () => mockRepo.getSpeedHistory(),
      ).thenAnswer((_) async => Result.success(tSpeedHistory));
      when(
        () => mockRepo.getWeeklyComparison(),
      ).thenAnswer((_) async => const Result.success(tWeeklyComparison));

      await readNotifier().loadProgress();

      final state = readState();
      expect(state.error, isNotNull);
      expect(state.summary, tSummary); // Summary still loaded
      expect(state.topicProgress, isEmpty);
    });

    test('chart data failures do not affect main data', () async {
      when(
        () => mockRepo.getProgressSummary(),
      ).thenAnswer((_) async => const Result.success(tSummary));
      when(
        () => mockRepo.getAllTopicProgress(),
      ).thenAnswer((_) async => const Result.success(tTopicProgress));
      // Chart calls fail
      when(() => mockRepo.getAccuracyHistory()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );
      when(() => mockRepo.getSpeedHistory()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );
      when(() => mockRepo.getWeeklyComparison()).thenAnswer(
        (_) async => const Result.failure(ServerFailure(message: 'Error')),
      );

      await readNotifier().loadProgress();
      await Future<void>.delayed(Duration.zero);

      final state = readState();
      expect(state.hasData, true);
      expect(state.summary, tSummary);
      expect(state.topicProgress, tTopicProgress);
      expect(state.error, isNull); // No error from chart failures
      expect(state.hasChartData, false);
      expect(state.isLoadingCharts, false);
    });
  });

  // ─── refresh ─────────────────────────────────────────────────────────

  group('refresh', () {
    test('reloads all data', () async {
      stubSuccessfulLoad();

      await readNotifier().refresh();

      final state = readState();
      expect(state.hasData, true);
      verify(() => mockRepo.getProgressSummary()).called(1);
      verify(() => mockRepo.getAllTopicProgress()).called(1);
    });
  });

  // ─── ProgressState copyWith ──────────────────────────────────────────

  group('ProgressState', () {
    test('copyWith preserves unmodified fields', () {
      const state = ProgressState(
        summary: tSummary,
        topicProgress: tTopicProgress,
        isLoading: false,
        error: null,
      );

      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.summary, tSummary);
      expect(updated.topicProgress, tTopicProgress);
    });

    test('hasData returns true when summary is present', () {
      const state = ProgressState(summary: tSummary);
      expect(state.hasData, true);
    });

    test('hasData returns false when summary is null', () {
      const state = ProgressState();
      expect(state.hasData, false);
    });

    test('hasChartData returns true when accuracy history is not empty', () {
      final state = ProgressState(accuracyHistory: tAccuracyHistory);
      expect(state.hasChartData, true);
    });

    test('hasChartData returns true when weekly comparison is present', () {
      const state = ProgressState(weeklyComparison: tWeeklyComparison);
      expect(state.hasChartData, true);
    });

    test('hasChartData returns false when all chart data is empty', () {
      const state = ProgressState();
      expect(state.hasChartData, false);
    });
  });
}
