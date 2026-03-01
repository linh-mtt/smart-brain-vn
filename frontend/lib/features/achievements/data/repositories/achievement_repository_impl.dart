import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../datasources/achievement_remote_datasource.dart';
import '../models/achievement_model.dart';

/// Implementation of [AchievementRepository] that communicates
/// with the remote data source.
class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl({
    required AchievementRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final AchievementRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<AchievementEntity>>> getAchievements() async {
    try {
      final models = await _remoteDatasource.getAchievements();
      final entities = models.map((m) => m.toEntity()).toList();
      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get achievements: ${e.toString()}'),
      );
    }
  }
}
