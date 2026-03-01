import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/practice_question_model.dart';
import '../../data/models/session_feedback_model.dart';
import '../../domain/repositories/practice_repository.dart';
import '../providers/practice_providers.dart';

/// State for a practice session.
class PracticeSessionState {
  const PracticeSessionState({
    this.sessionId,
    this.topic = '',
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.totalPoints = 0,
    this.comboCount = 0,
    this.comboMultiplier = 1.0,
    this.maxCombo = 0,
    this.streak = 0,
    this.correctCount = 0,
    this.feedback = const [],
    this.currentFeedback,
    this.isCompleted = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.difficultyStart = 1,
    this.currentDifficulty = 1,
    this.totalTimeMs = 0,
    this.questionStartTime,
  });

  /// Session ID from the backend.
  final String? sessionId;

  /// Practice topic.
  final String topic;

  /// All questions in this session.
  final List<PracticeQuestionModel> questions;

  /// Index of the current question.
  final int currentIndex;

  /// Total score earned.
  final int score;

  /// Maximum possible points.
  final int totalPoints;

  /// Current combo count.
  final int comboCount;

  /// Current combo multiplier.
  final double comboMultiplier;

  /// Max combo achieved in session.
  final int maxCombo;

  /// Current streak.
  final int streak;

  /// Number of correct answers.
  final int correctCount;

  /// Feedback for each question (null = not answered yet).
  final List<SessionFeedbackModel?> feedback;

  /// The most recent feedback received (for animation triggers).
  final SessionFeedbackModel? currentFeedback;

  /// Whether the session is completed.
  final bool isCompleted;

  /// Whether loading (starting session).
  final bool isLoading;

  /// Whether submitting an answer.
  final bool isSubmitting;

  /// Error message, if any.
  final String? error;

  /// Starting difficulty.
  final int difficultyStart;

  /// Current adaptive difficulty.
  final int currentDifficulty;

  /// Total time spent in milliseconds.
  final int totalTimeMs;

  /// When the current question started (for measuring response time).
  final DateTime? questionStartTime;

  /// The current question, if available.
  PracticeQuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
      ? questions[currentIndex]
      : null;

  /// Accuracy percentage (0-100).
  double get accuracy =>
      currentIndex > 0 ? (correctCount / currentIndex) * 100 : 0;

  /// Creates a copy with modified fields.
  PracticeSessionState copyWith({
    String? sessionId,
    String? topic,
    List<PracticeQuestionModel>? questions,
    int? currentIndex,
    int? score,
    int? totalPoints,
    int? comboCount,
    double? comboMultiplier,
    int? maxCombo,
    int? streak,
    int? correctCount,
    List<SessionFeedbackModel?>? feedback,
    SessionFeedbackModel? currentFeedback,
    bool? isCompleted,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    int? difficultyStart,
    int? currentDifficulty,
    int? totalTimeMs,
    DateTime? questionStartTime,
  }) {
    return PracticeSessionState(
      sessionId: sessionId ?? this.sessionId,
      topic: topic ?? this.topic,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      totalPoints: totalPoints ?? this.totalPoints,
      comboCount: comboCount ?? this.comboCount,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      maxCombo: maxCombo ?? this.maxCombo,
      streak: streak ?? this.streak,
      correctCount: correctCount ?? this.correctCount,
      feedback: feedback ?? this.feedback,
      currentFeedback: currentFeedback,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      difficultyStart: difficultyStart ?? this.difficultyStart,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      questionStartTime: questionStartTime ?? this.questionStartTime,
    );
  }
}

/// Manages practice session state.
///
/// Handles starting sessions, submitting answers with response time tracking,
/// combo management, and question progression.
class PracticeSessionNotifier extends Notifier<PracticeSessionState> {
  late PracticeRepository _repository;

  @override
  PracticeSessionState build() {
    _repository = ref.read(practiceRepositoryProvider);
    return const PracticeSessionState();
  }

  /// Starts a new practice session.
  Future<void> startSession(String topic, {int questionCount = 5}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.startSession(
      topic: topic,
      questionCount: questionCount,
    );

    result.fold(
      onSuccess: (data) {
        final questions = data.questions
            .map(
              (e) => PracticeQuestionModel(
                id: e.id,
                questionText: e.questionText,
                correctAnswer: e.correctAnswer,
                options: e.options,
                explanation: e.explanation,
                topic: e.topic,
                difficultyLevel: e.difficultyLevel,
              ),
            )
            .toList();

        state = PracticeSessionState(
          sessionId: data.sessionId,
          topic: data.topic,
          questions: questions,
          feedback: List.filled(questions.length, null),
          totalPoints: questions.length * 20, // Max base points per question
          difficultyStart: data.difficultyStart,
          currentDifficulty: data.difficultyStart,
          questionStartTime: DateTime.now(),
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.displayMessage);
      },
    );
  }

  /// Submits the user's answer for the current question.
  Future<void> submitAnswer(double answer) async {
    final question = state.currentQuestion;
    final sessionId = state.sessionId;
    if (question == null || sessionId == null || state.isSubmitting) return;

    // Calculate response time
    final timeTakenMs = state.questionStartTime != null
        ? DateTime.now().difference(state.questionStartTime!).inMilliseconds
        : null;

    state = state.copyWith(isSubmitting: true);

    final result = await _repository.submitAnswer(
      sessionId: sessionId,
      questionId: question.id,
      topic: question.topic,
      difficultyLevel: question.difficultyLevel,
      questionText: question.questionText,
      correctAnswer: question.correctAnswer,
      answer: answer,
      timeTakenMs: timeTakenMs,
    );

    result.fold(
      onSuccess: (entity) {
        final feedbackModel = SessionFeedbackModel(
          isCorrect: entity.isCorrect,
          correctAnswer: entity.correctAnswer,
          pointsEarned: entity.pointsEarned,
          comboCount: entity.comboCount,
          comboMultiplier: entity.comboMultiplier,
          maxCombo: entity.maxCombo,
          newDifficulty: entity.newDifficulty,
          eloRating: entity.eloRating,
          streak: entity.streak,
          weakTopics: entity.weakTopics,
          sessionProgress: SessionProgressModel(
            totalQuestions: entity.sessionProgress.totalQuestions,
            correctCount: entity.sessionProgress.correctCount,
            totalPoints: entity.sessionProgress.totalPoints,
            totalTimeMs: entity.sessionProgress.totalTimeMs,
            accuracy: entity.sessionProgress.accuracy,
          ),
        );

        final updatedFeedback = List<SessionFeedbackModel?>.from(
          state.feedback,
        );
        updatedFeedback[state.currentIndex] = feedbackModel;

        state = state.copyWith(
          score: entity.sessionProgress.totalPoints,
          comboCount: entity.comboCount,
          comboMultiplier: entity.comboMultiplier,
          maxCombo: entity.maxCombo,
          streak: entity.streak,
          correctCount: entity.sessionProgress.correctCount,
          feedback: updatedFeedback,
          currentFeedback: feedbackModel,
          isSubmitting: false,
          currentDifficulty: entity.newDifficulty,
          totalTimeMs: entity.sessionProgress.totalTimeMs,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: failure.displayMessage,
        );
      },
    );
  }

  /// Advances to the next question, or marks session as completed.
  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        questionStartTime: DateTime.now(),
      );
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  /// Resets the practice session.
  void reset() {
    state = const PracticeSessionState();
  }
}
