/// Tracks a user's progress on a specific learning tip.
class TipProgressEntity {
  const TipProgressEntity({
    required this.tipId,
    this.isCompleted = false,
    this.quizScore,
    this.quizTotal,
    this.lastViewedAt,
    this.completedAt,
  });

  /// The tip this progress belongs to.
  final String tipId;

  /// Whether the tip has been completed (tutorial + quiz).
  final bool isCompleted;

  /// Number of correct quiz answers, or null if not attempted.
  final int? quizScore;

  /// Total number of quiz questions, or null if not attempted.
  final int? quizTotal;

  /// When the user last viewed this tip.
  final DateTime? lastViewedAt;

  /// When the tip was completed, or null if not completed.
  final DateTime? completedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipProgressEntity &&
          runtimeType == other.runtimeType &&
          tipId == other.tipId;

  @override
  int get hashCode => tipId.hashCode;
}
