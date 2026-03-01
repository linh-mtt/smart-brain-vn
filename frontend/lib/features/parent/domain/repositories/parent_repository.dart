import '../../../../core/errors/failures.dart';
import '../entities/child_progress_entity.dart';
import '../entities/child_summary_entity.dart';

/// Abstract repository defining parent dashboard operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class ParentRepository {
  /// Gets all children associated with the parent.
  Future<Result<List<ChildSummaryEntity>>> getChildren();

  /// Gets detailed progress for a specific child.
  Future<Result<ChildProgressEntity>> getChildProgress(String childId);

  /// Updates learning goals for a specific child.
  Future<Result<void>> updateChildGoals(
    String childId, {
    int? dailyExerciseTarget,
    int? dailyTimeTargetMinutes,
    List<String>? activeTopics,
  });
}
