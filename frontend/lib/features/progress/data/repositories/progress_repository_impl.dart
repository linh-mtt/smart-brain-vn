import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/progress_summary_entity.dart';
import '../../domain/entities/topic_progress_entity.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_datasource.dart';
import '../models/progress_summary_model.dart';
import '../models/topic_progress_model.dart';

/// Implementation of [ProgressRepository] that fetches data from the remote API.
///
/// Handles error mapping from [AppException] to [Failure].
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({required ProgressRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  final ProgressRemoteDatasource _remoteDatasource;

  @override
  Future<Result<ProgressSummaryEntity>> getProgressSummary() async {
    try {
      final model = await _remoteDatasource.getProgressSummary();
      return Result.success(model.toEntity());
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to get progress summary: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<TopicProgressEntity>> getTopicProgress(String topic) async {
    try {
      final model = await _remoteDatasource.getTopicProgress(topic);
      return Result.success(model.toEntity());
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to get topic progress: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<List<TopicProgressEntity>>> getAllTopicProgress() async {
    try {
      final models = await _remoteDatasource.getAllTopicProgress();
      return Result.success(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to get all topic progress: ${e.toString()}',
        ),
      );
    }
  }
}
