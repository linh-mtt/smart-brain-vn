import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/progress_summary_entity.dart';
import '../../domain/entities/topic_progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../providers/progress_providers.dart';

/// State for the progress feature.
class ProgressState {
  const ProgressState({
    this.summary,
    this.topicProgress = const [],
    this.isLoading = false,
    this.error,
  });

  /// The user's overall progress summary.
  final ProgressSummaryEntity? summary;

  /// Progress data for each topic.
  final List<TopicProgressEntity> topicProgress;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether data has been loaded successfully.
  bool get hasData => summary != null;

  /// Creates a copy with modified fields.
  ProgressState copyWith({
    ProgressSummaryEntity? summary,
    List<TopicProgressEntity>? topicProgress,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      summary: summary ?? this.summary,
      topicProgress: topicProgress ?? this.topicProgress,
      isLoading: isLoading ?? this.isLoading,
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

  /// Loads all progress data (summary + topic progress).
  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);

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

    state = ProgressState(
      summary: summary,
      topicProgress: topics,
      isLoading: false,
      error: error,
    );
  }

  /// Refreshes all progress data.
  Future<void> refresh() async {
    await loadProgress();
  }
}
