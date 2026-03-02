import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_math_kids/core/errors/exceptions.dart';
import 'package:smart_math_kids/core/errors/failures.dart';
import 'package:smart_math_kids/features/progress/data/datasources/progress_remote_datasource.dart';
import 'package:smart_math_kids/features/progress/data/models/chart_data_point_model.dart';
import 'package:smart_math_kids/features/progress/data/models/progress_summary_model.dart';
import 'package:smart_math_kids/features/progress/data/models/topic_progress_model.dart';
import 'package:smart_math_kids/features/progress/data/models/weekly_comparison_model.dart';
import 'package:smart_math_kids/features/progress/data/repositories/progress_repository_impl.dart';

class MockProgressRemoteDatasource extends Mock
    implements ProgressRemoteDatasource {}

void main() {
  late MockProgressRemoteDatasource mockDatasource;
  late ProgressRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockProgressRemoteDatasource();
    repository = ProgressRepositoryImpl(remoteDatasource: mockDatasource);
  });

  // ─── Test Data ───────────────────────────────────────────────────────

  final tSummaryModel = ProgressSummaryModel(
    totalPoints: 500,
    currentStreak: 3,
    longestStreak: 7,
    totalExercises: 50,
    accuracyRate: 85.0,
    level: 5,
    xpToNextLevel: 200,
  );

  final tTopicModel = TopicProgressModel(
    topic: 'addition',
    masteryScore: 75.0,
    totalAnswered: 30,
    correctCount: 22,
    recentScores: [true, true, false, true, true],
  );

  final tChartDataPoints = [
    const ChartDataPointModel(date: '2025-01-01', value: 80.0),
    const ChartDataPointModel(date: '2025-01-02', value: 85.0),
    const ChartDataPointModel(date: '2025-01-03', value: 90.0),
  ];

  const tWeeklyComparison = WeeklyComparisonModel(
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    thisWeek: [10, 15, 20, 12, 18, 25, 8],
    lastWeek: [8, 12, 15, 10, 14, 20, 6],
    thisWeekAverage: 15.4,
    lastWeekAverage: 12.1,
    improvementPercent: 27.3,
  );

  // ─── getProgressSummary ──────────────────────────────────────────────

  group('getProgressSummary', () {
    test('returns success with entity when datasource succeeds', () async {
      when(
        () => mockDatasource.getProgressSummary(),
      ).thenAnswer((_) async => tSummaryModel);

      final result = await repository.getProgressSummary();

      expect(result.isSuccess, true);
      final entity = result.dataOrNull!;
      expect(entity.totalPoints, 500);
      expect(entity.currentStreak, 3);
      expect(entity.longestStreak, 7);
      expect(entity.totalExercises, 50);
      expect(entity.accuracyRate, 85.0);
      expect(entity.level, 5);
      expect(entity.xpToNextLevel, 200);
      verify(() => mockDatasource.getProgressSummary()).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getProgressSummary(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getProgressSummary();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.getProgressSummary(),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getProgressSummary();

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  // ─── getTopicProgress ────────────────────────────────────────────────

  group('getTopicProgress', () {
    test('returns success with entity when datasource succeeds', () async {
      when(
        () => mockDatasource.getTopicProgress('addition'),
      ).thenAnswer((_) async => tTopicModel);

      final result = await repository.getTopicProgress('addition');

      expect(result.isSuccess, true);
      final entity = result.dataOrNull!;
      expect(entity.topic, 'addition');
      expect(entity.masteryScore, 75.0);
      expect(entity.totalAnswered, 30);
      expect(entity.correctCount, 22);
      verify(() => mockDatasource.getTopicProgress('addition')).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getTopicProgress(any()),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getTopicProgress('addition');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  // ─── getAllTopicProgress ──────────────────────────────────────────────

  group('getAllTopicProgress', () {
    test(
      'returns success with list of entities when datasource succeeds',
      () async {
        when(
          () => mockDatasource.getAllTopicProgress(),
        ).thenAnswer((_) async => [tTopicModel]);

        final result = await repository.getAllTopicProgress();

        expect(result.isSuccess, true);
        final entities = result.dataOrNull!;
        expect(entities.length, 1);
        expect(entities.first.topic, 'addition');
        verify(() => mockDatasource.getAllTopicProgress()).called(1);
      },
    );

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getAllTopicProgress(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getAllTopicProgress();

      expect(result.isFailure, true);
    });
  });

  // ─── getAccuracyHistory ──────────────────────────────────────────────

  group('getAccuracyHistory', () {
    test('returns success with entities when datasource succeeds', () async {
      when(
        () => mockDatasource.getAccuracyHistory(),
      ).thenAnswer((_) async => tChartDataPoints);

      final result = await repository.getAccuracyHistory();

      expect(result.isSuccess, true);
      final entities = result.dataOrNull!;
      expect(entities.length, 3);
      expect(entities[0].date, DateTime.parse('2025-01-01'));
      expect(entities[0].value, 80.0);
      expect(entities[2].value, 90.0);
      verify(() => mockDatasource.getAccuracyHistory()).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getAccuracyHistory(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getAccuracyHistory();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.getAccuracyHistory(),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getAccuracyHistory();

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });

  // ─── getSpeedHistory ─────────────────────────────────────────────────

  group('getSpeedHistory', () {
    test('returns success with entities when datasource succeeds', () async {
      when(
        () => mockDatasource.getSpeedHistory(),
      ).thenAnswer((_) async => tChartDataPoints);

      final result = await repository.getSpeedHistory();

      expect(result.isSuccess, true);
      final entities = result.dataOrNull!;
      expect(entities.length, 3);
      verify(() => mockDatasource.getSpeedHistory()).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getSpeedHistory(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getSpeedHistory();

      expect(result.isFailure, true);
    });
  });

  // ─── getWeeklyComparison ─────────────────────────────────────────────

  group('getWeeklyComparison', () {
    test('returns success with entity when datasource succeeds', () async {
      when(
        () => mockDatasource.getWeeklyComparison(),
      ).thenAnswer((_) async => tWeeklyComparison);

      final result = await repository.getWeeklyComparison();

      expect(result.isSuccess, true);
      final entity = result.dataOrNull!;
      expect(entity.days.length, 7);
      expect(entity.thisWeekAverage, 15.4);
      expect(entity.lastWeekAverage, 12.1);
      expect(entity.improvementPercent, 27.3);
      verify(() => mockDatasource.getWeeklyComparison()).called(1);
    });

    test('returns failure when datasource throws AppException', () async {
      when(
        () => mockDatasource.getWeeklyComparison(),
      ).thenThrow(const ServerException(message: 'Server error'));

      final result = await repository.getWeeklyComparison();

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'returns UnknownFailure when datasource throws generic exception',
      () async {
        when(
          () => mockDatasource.getWeeklyComparison(),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getWeeklyComparison();

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });
}
