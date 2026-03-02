import '../../../../core/errors/failures.dart';
import '../entities/progress_summary_entity.dart';
import '../entities/topic_progress_entity.dart';
import '../entities/chart_data_point_entity.dart';
import '../entities/weekly_comparison_entity.dart';

/// Abstract repository defining progress operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class ProgressRepository {
  /// Gets the user's overall progress summary.
  Future<Result<ProgressSummaryEntity>> getProgressSummary();

  /// Gets the user's progress for a specific topic.
  Future<Result<TopicProgressEntity>> getTopicProgress(String topic);

  /// Gets the user's progress for all topics.
  Future<Result<List<TopicProgressEntity>>> getAllTopicProgress();

  /// Gets the user's accuracy history for chart visualization.
  Future<Result<List<ChartDataPointEntity>>> getAccuracyHistory();

  /// Gets the user's speed history for chart visualization.
  Future<Result<List<ChartDataPointEntity>>> getSpeedHistory();

  /// Gets the user's weekly comparison data.
  Future<Result<WeeklyComparisonEntity>> getWeeklyComparison();
}
