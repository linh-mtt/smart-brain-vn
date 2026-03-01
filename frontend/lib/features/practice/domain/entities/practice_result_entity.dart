class PracticeResultEntity {
  const PracticeResultEntity({
    required this.sessionId,
    required this.userId,
    required this.topic,
    required this.status,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.totalPoints,
    required this.totalTimeMs,
    required this.maxCombo,
    required this.difficultyStart,
    required this.difficultyEnd,
    required this.startedAt,
    this.completedAt,
    required this.results,
  });

  final String sessionId;
  final String userId;
  final String topic;
  final String status;
  final int totalQuestions;
  final int correctCount;
  final double accuracy;
  final int totalPoints;
  final int totalTimeMs;
  final int maxCombo;
  final int difficultyStart;
  final int difficultyEnd;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ResultDetailEntity> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeResultEntity &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

class ResultDetailEntity {
  const ResultDetailEntity({
    required this.id,
    required this.questionText,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.pointsEarned,
    required this.comboCount,
    required this.comboMultiplier,
    this.timeTakenMs,
    required this.createdAt,
  });

  final String id;
  final String questionText;
  final double correctAnswer;
  final double userAnswer;
  final bool isCorrect;
  final int pointsEarned;
  final int comboCount;
  final double comboMultiplier;
  final int? timeTakenMs;
  final DateTime createdAt;
}
