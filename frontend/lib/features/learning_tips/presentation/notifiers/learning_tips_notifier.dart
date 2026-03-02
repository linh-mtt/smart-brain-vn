import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/learning_tip_entity.dart';
import '../../domain/entities/tip_progress_entity.dart';
import '../../domain/repositories/learning_tips_repository.dart';
import '../providers/learning_tips_providers.dart';

// =============================================================================
// List State + Notifier
// =============================================================================

/// State for the learning tips list page.
class LearningTipsListState {
  const LearningTipsListState({
    this.tips = const [],
    this.progressMap = const {},
    this.selectedCategory,
    this.isLoading = false,
    this.error,
  });

  /// All available tips.
  final List<LearningTipEntity> tips;

  /// Progress keyed by tipId.
  final Map<String, TipProgressEntity> progressMap;

  /// Currently selected category filter (null = show all).
  final String? selectedCategory;

  /// Whether tips are being loaded.
  final bool isLoading;

  /// Error message, if any.
  final String? error;

  /// Tips filtered by [selectedCategory].
  List<LearningTipEntity> get filteredTips {
    if (selectedCategory == null) return tips;
    return tips.where((t) => t.category == selectedCategory).toList();
  }

  /// Number of completed tips.
  int get completedCount =>
      progressMap.values.where((p) => p.isCompleted).length;

  /// Creates a copy with modified fields.
  LearningTipsListState copyWith({
    List<LearningTipEntity>? tips,
    Map<String, TipProgressEntity>? progressMap,
    String? selectedCategory,
    bool? isLoading,
    String? error,
  }) {
    return LearningTipsListState(
      tips: tips ?? this.tips,
      progressMap: progressMap ?? this.progressMap,
      selectedCategory: selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages the list of learning tips and their progress.
class LearningTipsListNotifier extends Notifier<LearningTipsListState> {
  late LearningTipsRepository _repository;

  @override
  LearningTipsListState build() {
    _repository = ref.read(learningTipsRepositoryProvider);
    return const LearningTipsListState();
  }

  /// Loads all tips and their progress.
  Future<void> loadTips() async {
    state = state.copyWith(isLoading: true, error: null);

    final tipsResult = await _repository.getAllTips();

    tipsResult.fold(
      onSuccess: (tips) async {
        final progressResult = await _repository.getAllProgress();

        progressResult.fold(
          onSuccess: (progressList) {
            final map = <String, TipProgressEntity>{};
            for (final p in progressList) {
              map[p.tipId] = p;
            }
            state = state.copyWith(
              tips: tips,
              progressMap: map,
              isLoading: false,
            );
          },
          onFailure: (failure) {
            // Tips loaded but progress failed — show tips without progress.
            state = state.copyWith(tips: tips, isLoading: false);
          },
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.displayMessage);
      },
    );
  }

  /// Filters tips by [category]. Pass null to show all.
  void filterByCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Reloads only progress data (tips stay cached).
  Future<void> refreshProgress() async {
    final result = await _repository.getAllProgress();

    result.fold(
      onSuccess: (progressList) {
        final map = <String, TipProgressEntity>{};
        for (final p in progressList) {
          map[p.tipId] = p;
        }
        state = state.copyWith(progressMap: map);
      },
      onFailure: (_) {
        // Silently fail — existing progress remains.
      },
    );
  }
}

// =============================================================================
// Detail State + Notifier
// =============================================================================

/// State for the tip detail / quiz page.
class TipDetailState {
  const TipDetailState({
    this.tip,
    this.currentStepIndex = 0,
    this.isQuizMode = false,
    this.currentQuizIndex = 0,
    this.selectedAnswerIndex,
    this.quizAnswers = const {},
    this.quizCompleted = false,
    this.correctCount = 0,
    this.showExplanation = false,
    this.isLoading = false,
    this.error,
  });

  /// The loaded tip.
  final LearningTipEntity? tip;

  /// Current tutorial step index.
  final int currentStepIndex;

  /// Whether we are in quiz mode (vs tutorial mode).
  final bool isQuizMode;

  /// Current quiz question index.
  final int currentQuizIndex;

  /// The answer the user selected (null = not yet selected).
  final int? selectedAnswerIndex;

  /// Map of question index → selected option index.
  final Map<int, int> quizAnswers;

  /// Whether the quiz has been completed.
  final bool quizCompleted;

  /// Number of correct quiz answers.
  final int correctCount;

  /// Whether the explanation for the current answer is showing.
  final bool showExplanation;

  /// Whether the tip is loading.
  final bool isLoading;

  /// Error message, if any.
  final String? error;

  /// Total tutorial steps for this tip.
  int get totalSteps => tip?.steps.length ?? 0;

  /// Total quiz questions for this tip.
  int get totalQuestions => tip?.quizQuestions.length ?? 0;

  /// Whether the user is on the last tutorial step.
  bool get isLastStep => currentStepIndex >= totalSteps - 1;

  /// Creates a copy with modified fields.
  TipDetailState copyWith({
    LearningTipEntity? tip,
    int? currentStepIndex,
    bool? isQuizMode,
    int? currentQuizIndex,
    int? selectedAnswerIndex,
    Map<int, int>? quizAnswers,
    bool? quizCompleted,
    int? correctCount,
    bool? showExplanation,
    bool? isLoading,
    String? error,
  }) {
    return TipDetailState(
      tip: tip ?? this.tip,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isQuizMode: isQuizMode ?? this.isQuizMode,
      currentQuizIndex: currentQuizIndex ?? this.currentQuizIndex,
      selectedAnswerIndex: selectedAnswerIndex,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      quizCompleted: quizCompleted ?? this.quizCompleted,
      correctCount: correctCount ?? this.correctCount,
      showExplanation: showExplanation ?? this.showExplanation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages the detail view and quiz for a single learning tip.
class TipDetailNotifier extends Notifier<TipDetailState> {
  late LearningTipsRepository _repository;

  @override
  TipDetailState build() {
    _repository = ref.read(learningTipsRepositoryProvider);
    return const TipDetailState();
  }

  /// Loads a tip by [tipId].
  Future<void> loadTip(String tipId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTipById(tipId);

    result.fold(
      onSuccess: (tip) {
        state = TipDetailState(tip: tip);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.displayMessage);
      },
    );
  }

  /// Advances to the next tutorial step.
  void nextStep() {
    if (state.tip == null) return;
    if (state.currentStepIndex < state.tip!.steps.length - 1) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }

  /// Goes to the previous tutorial step.
  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }

  /// Transitions from tutorial mode to quiz mode.
  void startQuiz() {
    state = state.copyWith(
      isQuizMode: true,
      currentQuizIndex: 0,
      quizAnswers: {},
      correctCount: 0,
      quizCompleted: false,
    );
  }

  /// Selects an answer option for the current quiz question.
  void selectAnswer(int optionIndex) {
    if (state.showExplanation || state.quizCompleted) return;
    state = state.copyWith(selectedAnswerIndex: optionIndex);
  }

  /// Submits the selected answer, shows explanation, then advances.
  void submitAnswer() {
    final tip = state.tip;
    if (tip == null || state.selectedAnswerIndex == null) return;

    final question = tip.quizQuestions[state.currentQuizIndex];
    final isCorrect = state.selectedAnswerIndex == question.correctIndex;

    final updatedAnswers = Map<int, int>.from(state.quizAnswers);
    updatedAnswers[state.currentQuizIndex] = state.selectedAnswerIndex!;

    state = state.copyWith(
      quizAnswers: updatedAnswers,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
      showExplanation: true,
    );
  }

  /// Moves to the next quiz question, or completes the quiz.
  void nextQuestion() {
    if (state.tip == null) return;

    if (state.currentQuizIndex < state.tip!.quizQuestions.length - 1) {
      state = state.copyWith(
        currentQuizIndex: state.currentQuizIndex + 1,
        showExplanation: false,
      );
    } else {
      state = state.copyWith(quizCompleted: true, showExplanation: false);
    }
  }

  /// Saves completion to Hive via the repository.
  Future<void> completeQuiz() async {
    final tip = state.tip;
    if (tip == null) return;

    await _repository.markTipCompleted(
      tip.id,
      quizScore: state.correctCount,
      quizTotal: tip.quizQuestions.length,
    );
  }

  /// Resets to initial state.
  void reset() {
    state = const TipDetailState();
  }
}
