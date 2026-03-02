import 'dart:async';

import '../../domain/entities/competition_question_entity.dart';
import '../../domain/entities/match_result_entity.dart';
import '../../domain/entities/opponent_entity.dart';
import '../services/competition_websocket_service.dart';

/// Events received from the competition WebSocket.
sealed class MatchEvent {
  const MatchEvent();
}

/// An opponent has been found and the match is about to start.
class MatchFoundEvent extends MatchEvent {
  const MatchFoundEvent({
    required this.matchId,
    required this.opponent,
    required this.totalQuestions,
  });

  final String matchId;
  final OpponentEntity opponent;
  final int totalQuestions;
}

/// Countdown tick before the match begins.
class CountdownEvent extends MatchEvent {
  const CountdownEvent({required this.secondsRemaining});

  final int secondsRemaining;
}

/// A new question has been delivered.
class QuestionEvent extends MatchEvent {
  const QuestionEvent({
    required this.question,
    required this.questionIndex,
    required this.timeRemainingSeconds,
  });

  final CompetitionQuestionEntity question;
  final int questionIndex;
  final int timeRemainingSeconds;
}

/// Result of the player's submitted answer.
class AnswerResultEvent extends MatchEvent {
  const AnswerResultEvent({
    required this.isCorrect,
    required this.pointsEarned,
    required this.correctAnswer,
  });

  final bool isCorrect;
  final int pointsEarned;
  final double correctAnswer;
}

/// Score update for both players.
class ScoreUpdateEvent extends MatchEvent {
  const ScoreUpdateEvent({
    required this.playerScore,
    required this.opponentScore,
    required this.playerStreak,
    required this.opponentStreak,
  });

  final int playerScore;
  final int opponentScore;
  final int playerStreak;
  final int opponentStreak;
}

/// The match is complete, final result available.
class MatchCompleteEvent extends MatchEvent {
  const MatchCompleteEvent({required this.result});

  final MatchResultEntity result;
}

/// The opponent has disconnected.
class OpponentDisconnectEvent extends MatchEvent {
  const OpponentDisconnectEvent();
}

/// The opponent has reconnected.
class OpponentReconnectEvent extends MatchEvent {
  const OpponentReconnectEvent();
}

/// Data source that converts raw WebSocket JSON into typed [MatchEvent]s.
///
/// Sits between the raw [CompetitionWebSocketService] and the repository layer.
class CompetitionWebSocketDatasource {
  CompetitionWebSocketDatasource({
    required CompetitionWebSocketService webSocketService,
  }) : _webSocketService = webSocketService;

  final CompetitionWebSocketService _webSocketService;

  /// Stream of typed match events parsed from raw WebSocket messages.
  Stream<MatchEvent> get matchEvents =>
      _webSocketService.messages.transform(_eventTransformer);

  /// Stream of WebSocket connection state changes.
  Stream<WsConnectionState> get connectionState =>
      _webSocketService.connectionState;

  /// Current connection state.
  WsConnectionState get currentConnectionState =>
      _webSocketService.currentState;

  /// Connects to the WebSocket with the given auth [token].
  Future<void> connect(String token) => _webSocketService.connect(token);

  /// Disconnects from the WebSocket.
  Future<void> disconnect() => _webSocketService.disconnect();

  /// Sends a find-match request.
  void findMatch() {
    _webSocketService.send({'event_type': 'find_match', 'payload': {}});
  }

  /// Submits an answer for the current question.
  void submitAnswer({
    required String matchId,
    required String questionId,
    required double answer,
    int? timeTakenMs,
  }) {
    _webSocketService.send({
      'event_type': 'submit_answer',
      'payload': {
        'match_id': matchId,
        'question_id': questionId,
        'answer': answer,
        if (timeTakenMs != null) 'time_taken_ms': timeTakenMs,
      },
    });
  }

  /// Disposes underlying WebSocket service resources.
  Future<void> dispose() => _webSocketService.dispose();

  /// Transformer that converts raw JSON maps to typed [MatchEvent]s.
  static final _eventTransformer =
      StreamTransformer<Map<String, dynamic>, MatchEvent>.fromHandlers(
        handleData: (data, sink) {
          final event = _parseEvent(data);
          if (event != null) {
            sink.add(event);
          }
        },
      );

  static MatchEvent? _parseEvent(Map<String, dynamic> data) {
    final eventType = data['event_type'] as String?;
    final payload = data['payload'] as Map<String, dynamic>? ?? {};

    return switch (eventType) {
      'match_found' => MatchFoundEvent(
        matchId: payload['match_id'] as String? ?? '',
        opponent: OpponentEntity(
          id: payload['opponent_id'] as String? ?? '',
          username: payload['opponent_username'] as String? ?? '',
          displayName: payload['opponent_display_name'] as String? ?? '',
          avatarUrl: payload['opponent_avatar_url'] as String? ?? '',
          eloRating: payload['opponent_elo_rating'] as int? ?? 0,
        ),
        totalQuestions: payload['total_questions'] as int? ?? 10,
      ),
      'countdown' => CountdownEvent(
        secondsRemaining: payload['seconds_remaining'] as int? ?? 0,
      ),
      'question' => QuestionEvent(
        question: CompetitionQuestionEntity(
          id: payload['question_id'] as String? ?? '',
          questionText: payload['question_text'] as String? ?? '',
          correctAnswer: (payload['correct_answer'] as num?)?.toDouble() ?? 0.0,
          options:
              (payload['options'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          difficultyLevel: payload['difficulty_level'] as int? ?? 1,
          topic: payload['topic'] as String? ?? '',
        ),
        questionIndex: payload['question_index'] as int? ?? 0,
        timeRemainingSeconds: payload['time_remaining_seconds'] as int? ?? 30,
      ),
      'answer_result' => AnswerResultEvent(
        isCorrect: payload['is_correct'] as bool? ?? false,
        pointsEarned: payload['points_earned'] as int? ?? 0,
        correctAnswer: (payload['correct_answer'] as num?)?.toDouble() ?? 0.0,
      ),
      'score_update' => ScoreUpdateEvent(
        playerScore: payload['player_score'] as int? ?? 0,
        opponentScore: payload['opponent_score'] as int? ?? 0,
        playerStreak: payload['player_streak'] as int? ?? 0,
        opponentStreak: payload['opponent_streak'] as int? ?? 0,
      ),
      'match_complete' => MatchCompleteEvent(
        result: MatchResultEntity(
          matchId: payload['match_id'] as String? ?? '',
          isVictory: payload['is_victory'] as bool? ?? false,
          playerScore: payload['player_score'] as int? ?? 0,
          opponentScore: payload['opponent_score'] as int? ?? 0,
          questionsAnswered: payload['questions_answered'] as int? ?? 0,
          correctAnswers: payload['correct_answers'] as int? ?? 0,
          accuracy: (payload['accuracy'] as num?)?.toDouble() ?? 0.0,
          totalTimeMs: payload['total_time_ms'] as int? ?? 0,
          pointsEarned: payload['points_earned'] as int? ?? 0,
          eloChange: payload['elo_change'] as int? ?? 0,
          opponentName: payload['opponent_name'] as String? ?? '',
        ),
      ),
      'opponent_disconnect' => const OpponentDisconnectEvent(),
      'opponent_reconnect' => const OpponentReconnectEvent(),
      _ => null,
    };
  }
}
