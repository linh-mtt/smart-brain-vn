import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_datasource.dart';
import '../models/leaderboard_entry_model.dart';

/// Implementation of [LeaderboardRepository] that communicates
/// with the remote data source.
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl({
    required LeaderboardRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final LeaderboardRemoteDatasource _remoteDatasource;

  @override
  Future<Result<List<LeaderboardEntryEntity>>> getLeaderboard({
    String? period,
  }) async {
    try {
      final models = await _remoteDatasource.getLeaderboard(period: period);
      final entities = models.map((m) => m.toEntity()).toList();
      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get leaderboard: ${e.toString()}'),
      );
    }
  }
}
