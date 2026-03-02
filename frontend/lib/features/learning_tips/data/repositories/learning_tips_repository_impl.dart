import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/learning_tip_entity.dart';
import '../../domain/entities/tip_progress_entity.dart';
import '../../domain/repositories/learning_tips_repository.dart';
import '../datasources/learning_tips_local_datasource.dart';

/// Implementation of [LearningTipsRepository] that uses local-only data.
///
/// Tip content is hardcoded in the datasource. Only progress tracking
/// uses Hive persistence. Handles error mapping from exceptions to
/// domain failures.
class LearningTipsRepositoryImpl implements LearningTipsRepository {
  LearningTipsRepositoryImpl({
    required LearningTipsLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  final LearningTipsLocalDatasource _localDatasource;

  @override
  Future<Result<List<LearningTipEntity>>> getAllTips() async {
    try {
      final tips = _localDatasource.getAllTipContent();
      return Result.success(tips);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get learning tips: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<LearningTipEntity>> getTipById(String tipId) async {
    try {
      final tip = _localDatasource.getTipContentById(tipId);
      return Result.success(tip);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get tip: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<TipProgressEntity>>> getAllProgress() async {
    try {
      final progress = await _localDatasource.getAllProgress();
      return Result.success(progress);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get tip progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> markTipCompleted(
    String tipId, {
    int? quizScore,
    int? quizTotal,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _localDatasource.saveProgress(tipId, {
        'isCompleted': true,
        'quizScore': quizScore,
        'quizTotal': quizTotal,
        'lastViewedAt': now,
        'completedAt': now,
      });
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to mark tip completed: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> resetProgress() async {
    try {
      await _localDatasource.clearAllProgress();
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(
          message: 'Failed to reset tip progress: ${e.toString()}',
        ),
      );
    }
  }
}
