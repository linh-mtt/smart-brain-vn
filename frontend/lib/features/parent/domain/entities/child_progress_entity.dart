import '../../../progress/domain/entities/topic_progress_entity.dart';
import 'child_summary_entity.dart';
import 'daily_goal_entity.dart';
import 'recent_exercise_entity.dart';

/// Domain entity representing detailed child progress.
///
/// This is a plain Dart class that represents the core child progress
/// concept in the domain layer, independent of data sources.
class ChildProgressEntity {
  const ChildProgressEntity({
    required this.child,
    required this.topicMastery,
    this.dailyGoal,
    required this.recentActivity,
  });

  /// Child summary information.
  final ChildSummaryEntity child;

  /// Topic mastery progress.
  final List<TopicProgressEntity> topicMastery;

  /// Daily learning goals.
  final DailyGoalEntity? dailyGoal;

  /// Recent exercise activity.
  final List<RecentExerciseEntity> recentActivity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProgressEntity &&
          runtimeType == other.runtimeType &&
          child == other.child;

  @override
  int get hashCode => child.hashCode;

  @override
  String toString() =>
      'ChildProgressEntity(child: $child, topics: ${topicMastery.length})';
}
