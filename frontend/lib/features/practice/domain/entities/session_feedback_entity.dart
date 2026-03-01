class SessionFeedbackEntity {
  const SessionFeedbackEntity({
    required this.isCorrect,
    required this.correctAnswer,
    required this.pointsEarned,
    required this.comboCount,
    required this.comboMultiplier,
    required this.maxCombo,
    required this.newDifficulty,
    required this.eloRating,
    required this.streak,
    required this.weakTopics,
    required this.sessionProgress,
  });

  final bool isCorrect;
  final double correctAnswer;
  final int pointsEarned;
  final int comboCount;
  final double comboMultiplier;
  final int maxCombo;
  final int newDifficulty;
  final double eloRating;
  final int streak;
  final List<String> weakTopics;
  final SessionProgressEntity sessionProgress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionFeedbackEntity &&
          runtimeType == other.runtimeType &&
          isCorrect == other.isCorrect &&
          comboCount == other.comboCount;

  @override
  int get hashCode => Object.hash(isCorrect, comboCount);
}

class SessionProgressEntity {
  const SessionProgressEntity({
    required this.totalQuestions,
    required this.correctCount,
    required this.totalPoints,
    required this.totalTimeMs,
    required this.accuracy,
  });

  final int totalQuestions;
  final int correctCount;
  final int totalPoints;
  final int totalTimeMs;
  final double accuracy;
}
