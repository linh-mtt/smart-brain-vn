import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../progress/data/models/topic_progress_model.dart';
import '../../domain/entities/child_progress_entity.dart';
import '../../domain/entities/child_summary_entity.dart';
import '../../domain/entities/daily_goal_entity.dart';
import '../../domain/entities/recent_exercise_entity.dart';
import '../../domain/repositories/parent_repository.dart';
import '../datasources/parent_remote_datasource.dart';
import '../models/child_summary_model.dart';

/// Implementation of [ParentRepository] that communicates
/// with the remote data source.
class ParentRepositoryImpl implements ParentRepository {
  ParentRepositoryImpl({required ParentRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  final ParentRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<ChildSummaryEntity>>> getChildren() async {
    try {
      final models = await _remoteDatasource.getChildren();
      final entities = models.map((m) => m.toEntity()).toList();
      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get children: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<ChildProgressEntity>> getChildProgress(String childId) async {
    try {
      final model = await _remoteDatasource.getChildProgress(childId);
      final entity = ChildProgressEntity(
        child: model.child.toEntity(),
        topicMastery: model.topicMastery.map((m) => m.toEntity()).toList(),
        dailyGoal: model.dailyGoal != null
            ? DailyGoalEntity(
                dailyExerciseTarget: model.dailyGoal!.dailyExerciseTarget,
                dailyTimeTargetMinutes: model.dailyGoal!.dailyTimeTargetMinutes,
                activeTopics: model.dailyGoal!.activeTopics,
              )
            : null,
        recentActivity: model.recentActivity
            .map(
              (m) => RecentExerciseEntity(
                id: m.id,
                topic: m.topic,
                difficulty: m.difficulty,
                isCorrect: m.isCorrect,
                pointsEarned: m.pointsEarned,
                createdAt: m.createdAt,
              ),
            )
            .toList(),
      );
      return Result.success(entity);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to get child progress: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateChildGoals(
    String childId, {
    int? dailyExerciseTarget,
    int? dailyTimeTargetMinutes,
    List<String>? activeTopics,
  }) async {
    try {
      await _remoteDatasource.updateChildGoals(
        childId,
        dailyExerciseTarget: dailyExerciseTarget,
        dailyTimeTargetMinutes: dailyTimeTargetMinutes,
        activeTopics: activeTopics,
      );
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to update child goals: ${e.toString()}',
        ),
      );
    }
  }
}
