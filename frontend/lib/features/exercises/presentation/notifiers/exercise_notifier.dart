import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/answer_feedback_model.dart';
import '../../data/models/exercise_model.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../providers/exercise_providers.dart';

/// State for an exercise session.
class ExerciseSessionState {
  const ExerciseSessionState({
    this.exercises = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.totalPoints = 0,
    this.feedback = const [],
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  /// All exercises in this session.
  final List<ExerciseModel> exercises;

  /// Index of the current exercise being answered.
  final int currentIndex;

  /// Total score earned so far.
  final int score;

  /// Maximum possible points.
  final int totalPoints;

  /// Feedback for each exercise (null = not answered yet).
  final List<AnswerFeedbackModel?> feedback;

  /// Whether the session is completed.
  final bool isCompleted;

  /// Whether an operation is in progress (loading exercises or submitting).
  final bool isLoading;

  /// Error message, if any.
  final String? error;

  /// The current exercise, if available.
  ExerciseModel? get currentExercise =>
      exercises.isNotEmpty && currentIndex < exercises.length
      ? exercises[currentIndex]
      : null;

  /// Creates a copy with modified fields.
  ExerciseSessionState copyWith({
    List<ExerciseModel>? exercises,
    int? currentIndex,
    int? score,
    int? totalPoints,
    List<AnswerFeedbackModel?>? feedback,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseSessionState(
      exercises: exercises ?? this.exercises,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      totalPoints: totalPoints ?? this.totalPoints,
      feedback: feedback ?? this.feedback,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages exercise session state.
///
/// Provides methods for loading exercises, submitting answers,
/// navigating between problems, and resetting the session.
class ExerciseSessionNotifier
    extends Notifier<ExerciseSessionState> {
  late ExerciseRepository _repository;

  @override
  ExerciseSessionState build() {
    _repository = ref.read(exerciseRepositoryProvider);
    return const ExerciseSessionState();
  }

  /// Loads exercises for the given topic and difficulty.
  Future<void> loadExercises(String topic, String difficulty) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.generateExercises(
      topic: topic,
      difficulty: difficulty,
    );

    result.fold(
      onSuccess: (entities) {
        final models = entities
            .map(
              (e) => ExerciseModel(
                id: e.id,
                questionText: e.questionText,
                options: e.options,
                difficulty: e.difficulty,
                topic: e.topic,
              ),
            )
            .toList();

        state = ExerciseSessionState(
          exercises: models,
          feedback: List.filled(models.length, null),
          totalPoints: models.length * 10,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.displayMessage);
      },
    );
  }

  /// Submits the user's answer for the current exercise.
  Future<void> submitAnswer(double answer) async {
    final exercise = state.currentExercise;
    if (exercise == null || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository.submitAnswer(
      exerciseId: exercise.id,
      answer: answer,
    );

    result.fold(
      onSuccess: (entity) {
        final feedbackModel = AnswerFeedbackModel(
          isCorrect: entity.isCorrect,
          correctAnswer: entity.correctAnswer,
          pointsEarned: entity.pointsEarned,
          explanation: entity.explanation,
        );

        final updatedFeedback = List<AnswerFeedbackModel?>.from(state.feedback);
        updatedFeedback[state.currentIndex] = feedbackModel;

        state = state.copyWith(
          score: state.score + entity.pointsEarned,
          feedback: updatedFeedback,
          isLoading: false,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.displayMessage);
      },
    );
  }

  /// Advances to the next problem, or marks session as completed.
  void nextProblem() {
    if (state.currentIndex < state.exercises.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  /// Resets the exercise session.
  void reset() {
    state = const ExerciseSessionState();
  }
}
