import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/competition_websocket_datasource.dart';
import '../../domain/entities/competition_question_entity.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/match_result_entity.dart';
import '../../domain/entities/opponent_entity.dart';
import '../../domain/repositories/competition_repository.dart';
import '../providers/competition_providers.dart';

/// Encouragement messages shown during a match.
const _encouragements = [
  'You\'re doing great! 🌟',
  'Keep it up, math star! ⭐',
  'Amazing work! 🎉',
  'You\'re on fire! 🔥',
  'Brilliant! Keep going! 💪',
  'Super brain power! 🧠',
  'Wow, you\'re fast! ⚡',
  'Math champion! 🏆',
];

/// State for a competition match.
class MatchState {
  const MatchState({
    this.status = MatchStatus.waiting,
    this.matchId,
    this.opponent,
    this.currentQuestion,
    this.questionIndex = 0,
    this.totalQuestions = 10,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.playerStreak = 0,
    this.opponentStreak = 0,
    this.timeRemainingSeconds = 0,
    this.countdownSeconds = 0,
    this.selectedAnswer,
    this.lastAnswerCorrect,
    this.matchResult,
    this.encouragementMessage,
    this.isLoading = false,
    this.error,
  });

  final MatchStatus status;
  final String? matchId;
  final OpponentEntity? opponent;
  final CompetitionQuestionEntity? currentQuestion;
  final int questionIndex;
  final int totalQuestions;
  final int playerScore;
  final int opponentScore;
  final int playerStreak;
  final int opponentStreak;
  final int timeRemainingSeconds;
  final int countdownSeconds;
  final double? selectedAnswer;
  final bool? lastAnswerCorrect;
  final MatchResultEntity? matchResult;
  final String? encouragementMessage;
  final bool isLoading;
  final String? error;

  /// Creates a copy with modified fields.
  /// Nullable fields [error], [lastAnswerCorrect], [encouragementMessage],
  /// and [selectedAnswer] reset to null when not explicitly passed.
  MatchState copyWith({
    MatchStatus? status,
    String? matchId,
    OpponentEntity? opponent,
    CompetitionQuestionEntity? currentQuestion,
    int? questionIndex,
    int? totalQuestions,
    int? playerScore,
    int? opponentScore,
    int? playerStreak,
    int? opponentStreak,
    int? timeRemainingSeconds,
    int? countdownSeconds,
    double? selectedAnswer,
    bool? lastAnswerCorrect,
    MatchResultEntity? matchResult,
    String? encouragementMessage,
    bool? isLoading,
    String? error,
  }) {
    return MatchState(
      status: status ?? this.status,
      matchId: matchId ?? this.matchId,
      opponent: opponent ?? this.opponent,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      questionIndex: questionIndex ?? this.questionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      playerStreak: playerStreak ?? this.playerStreak,
      opponentStreak: opponentStreak ?? this.opponentStreak,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      selectedAnswer: selectedAnswer,
      lastAnswerCorrect: lastAnswerCorrect,
      matchResult: matchResult ?? this.matchResult,
      encouragementMessage: encouragementMessage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages competition match state.
///
/// Handles match lifecycle: finding opponents, answering questions,
/// tracking scores, and processing results. Listens to WebSocket events
/// and updates state accordingly.
class MatchNotifier extends Notifier<MatchState> {
  late CompetitionRepository _repository;
  late CompetitionWebSocketDatasource _datasource;
  StreamSubscription<MatchEvent>? _eventSubscription;
  Timer? _questionTimer;
  int _encouragementIndex = 0;

  @override
  MatchState build() {
    _repository = ref.read(competitionRepositoryProvider);
    _datasource = ref.read(competitionWebSocketDatasourceProvider);

    ref.onDispose(() {
      _eventSubscription?.cancel();
      _questionTimer?.cancel();
    });

    return const MatchState();
  }

  /// Starts searching for a match.
  Future<void> findMatch() async {
    state = state.copyWith(isLoading: true, status: MatchStatus.waiting);

    _listenToEvents();

    final result = await _repository.findMatch();

    result.fold(
      onSuccess: (matchId) {
        state = state.copyWith(matchId: matchId, isLoading: false);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.displayMessage);
      },
    );
  }

  /// Submits an answer for the current question.
  Future<void> submitAnswer(double answer) async {
    final matchId = state.matchId;
    final question = state.currentQuestion;
    if (matchId == null || question == null) return;
    if (state.selectedAnswer != null) return; // Already answered.

    state = state.copyWith(selectedAnswer: answer);

    await _repository.submitAnswer(
      matchId: matchId,
      questionId: question.id,
      answer: answer,
    );
  }

  /// Disconnects from the current match.
  Future<void> leaveMatch() async {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _questionTimer?.cancel();
    _questionTimer = null;
    await _repository.disconnect();
    state = const MatchState();
  }

  /// Resets the match state.
  void reset() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _questionTimer?.cancel();
    _questionTimer = null;
    state = const MatchState();
  }

  void _listenToEvents() {
    _eventSubscription?.cancel();

    _eventSubscription = _datasource.matchEvents.listen((event) {
      switch (event) {
        case MatchFoundEvent():
          _onMatchFound(event);
        case CountdownEvent():
          _onCountdown(event);
        case QuestionEvent():
          _onQuestion(event);
        case AnswerResultEvent():
          _onAnswerResult(event);
        case ScoreUpdateEvent():
          _onScoreUpdate(event);
        case MatchCompleteEvent():
          _onMatchComplete(event);
        case OpponentDisconnectEvent():
          _onOpponentDisconnect();
        case OpponentReconnectEvent():
          _onOpponentReconnect();
      }
    });
  }

  void _onMatchFound(MatchFoundEvent event) {
    state = state.copyWith(
      matchId: event.matchId,
      opponent: event.opponent,
      totalQuestions: event.totalQuestions,
      status: MatchStatus.countdown,
      isLoading: false,
    );
  }

  void _onCountdown(CountdownEvent event) {
    state = state.copyWith(
      countdownSeconds: event.secondsRemaining,
      status: MatchStatus.countdown,
    );
  }

  void _onQuestion(QuestionEvent event) {
    _questionTimer?.cancel();

    state = state.copyWith(
      currentQuestion: event.question,
      questionIndex: event.questionIndex,
      timeRemainingSeconds: event.timeRemainingSeconds,
      status: MatchStatus.inProgress,
    );

    _startQuestionTimer(event.timeRemainingSeconds);
  }

  void _onAnswerResult(AnswerResultEvent event) {
    final message = event.isCorrect
        ? _encouragements[_encouragementIndex++ % _encouragements.length]
        : 'Don\'t worry, you\'ll get the next one! 💪';

    state = state.copyWith(
      lastAnswerCorrect: event.isCorrect,
      encouragementMessage: message,
    );
  }

  void _onScoreUpdate(ScoreUpdateEvent event) {
    state = state.copyWith(
      playerScore: event.playerScore,
      opponentScore: event.opponentScore,
      playerStreak: event.playerStreak,
      opponentStreak: event.opponentStreak,
    );
  }

  void _onMatchComplete(MatchCompleteEvent event) {
    _questionTimer?.cancel();
    state = state.copyWith(
      status: MatchStatus.completed,
      matchResult: event.result,
    );
  }

  void _onOpponentDisconnect() {
    state = state.copyWith(
      status: MatchStatus.disconnected,
      encouragementMessage: 'Your opponent left the match.',
    );
  }

  void _onOpponentReconnect() {
    state = state.copyWith(
      status: MatchStatus.inProgress,
      encouragementMessage: 'Your opponent is back! 🎮',
    );
  }

  void _startQuestionTimer(int seconds) {
    _questionTimer?.cancel();
    var remaining = seconds;

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(timeRemainingSeconds: 0);
      } else {
        state = state.copyWith(timeRemainingSeconds: remaining);
      }
    });
  }
}
