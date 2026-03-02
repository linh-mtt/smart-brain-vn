import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chart_data_point_entity.dart';
import '../../domain/entities/progress_summary_entity.dart';
import '../../domain/entities/topic_progress_entity.dart';
import '../../domain/entities/weekly_comparison_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../providers/progress_providers.dart';

/// State for the progress feature.
class ProgressState {
  const ProgressState({
    this.summary,
    this.topicProgress = const [],
    this.accuracyHistory = const [],
    this.speedHistory = const [],
    this.weeklyComparison,
    this.isLoading = false,
    this.isLoadingCharts = false,
    this.error,
  });

  /// The user's overall progress summary.
  final ProgressSummaryEntity? summary;

  /// Progress data for each topic.
  final List<TopicProgressEntity> topicProgress;

  /// Accuracy history data points for line chart.
  final List<ChartDataPointEntity> accuracyHistory;

  /// Speed history data points for line chart.
  final List<ChartDataPointEntity> speedHistory;

  /// Weekly comparison data for bar chart.
  final WeeklyComparisonEntity? weeklyComparison;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Whether chart data is currently being loaded.
  final bool isLoadingCharts;

  /// Error message if loading failed.
  final String? error;

  /// Whether data has been loaded successfully.
  bool get hasData => summary != null;

  /// Whether chart data has been loaded successfully.
  bool get hasChartData =>
      accuracyHistory.isNotEmpty ||
      speedHistory.isNotEmpty ||
      weeklyComparison != null;

  /// Creates a copy with modified fields.
  ProgressState copyWith({
    ProgressSummaryEntity? summary,
    List<TopicProgressEntity>? topicProgress,
    List<ChartDataPointEntity>? accuracyHistory,
    List<ChartDataPointEntity>? speedHistory,
    WeeklyComparisonEntity? weeklyComparison,
    bool? isLoading,
    bool? isLoadingCharts,
    String? error,
  }) {
    return ProgressState(
      summary: summary ?? this.summary,
      topicProgress: topicProgress ?? this.topicProgress,
      accuracyHistory: accuracyHistory ?? this.accuracyHistory,
      speedHistory: speedHistory ?? this.speedHistory,
      weeklyComparison: weeklyComparison ?? this.weeklyComparison,
      isLoading: isLoading ?? this.isLoading,
      isLoadingCharts: isLoadingCharts ?? this.isLoadingCharts,
      error: error,
    );
  }
}

/// Manages progress state for the application.
///
/// Provides methods to load and refresh progress data.
class ProgressNotifier extends Notifier<ProgressState> {
  late ProgressRepository _repository;

  @override
  ProgressState build() {
    _repository = ref.read(progressRepositoryProvider);
    return const ProgressState();
  }

  /// Loads all progress data (summary + topic progress + chart data).
  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, isLoadingCharts: true, error: null);

    // Load summary and topic progress in parallel
    final futures = await (
      _repository.getProgressSummary(),
      _repository.getAllTopicProgress(),
    ).wait;

    final summaryResult = futures.$1;
    final topicResult = futures.$2;

    ProgressSummaryEntity? summary;
    List<TopicProgressEntity> topics = [];
    String? error;

    summaryResult.fold(
      onSuccess: (data) => summary = data,
      onFailure: (failure) => error = failure.displayMessage,
    );

    topicResult.fold(
      onSuccess: (data) => topics = data,
      onFailure: (failure) => error ??= failure.displayMessage,
    );

    state = state.copyWith(
      summary: summary,
      topicProgress: topics,
      isLoading: false,
      error: error,
    );

    // Load chart data in parallel (non-blocking — errors won't affect main data)
    unawaited(_loadChartData());
  }

  /// Loads chart visualization data from the API.
  Future<void> _loadChartData() async {

    final chartFutures = await (
      _repository.getAccuracyHistory(),
      _repository.getSpeedHistory(),
      _repository.getWeeklyComparison(),
    ).wait;

    final accuracyResult = chartFutures.$1;
    final speedResult = chartFutures.$2;
    final weeklyResult = chartFutures.$3;

    List<ChartDataPointEntity> accuracy = [];
    List<ChartDataPointEntity> speed = [];
    WeeklyComparisonEntity? weekly;

    accuracyResult.fold(
      onSuccess: (data) => accuracy = data,
      onFailure: (_) {},
    );

    speedResult.fold(onSuccess: (data) => speed = data, onFailure: (_) {});

    weeklyResult.fold(onSuccess: (data) => weekly = data, onFailure: (_) {});

    state = state.copyWith(
      accuracyHistory: accuracy,
      speedHistory: speed,
      weeklyComparison: weekly,
      isLoadingCharts: false,
      error: state.error,
    );
  }

  /// Refreshes all progress data.
  Future<void> refresh() async {
    await loadProgress();
  }
}
