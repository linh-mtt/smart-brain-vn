import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/xp_profile_entity.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_datasource.dart';
import '../models/theme_model.dart';
import '../models/xp_profile_model.dart';

/// Implementation of [GamificationRepository] that communicates
/// with the remote data source.
class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl({
    required GamificationRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final GamificationRemoteDatasource _remoteDatasource;

  @override
  Future<Result<XpProfileEntity>> getXpProfile() async {
    try {
      final model = await _remoteDatasource.getXpProfile();
      return Result.success(model.toEntity());
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get XP profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<ThemeEntity>>> getThemes() async {
    try {
      final model = await _remoteDatasource.getThemes();
      final entities = model.themes.map((t) => t.toEntity()).toList();
      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get themes: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<ThemeEntity>> unlockTheme(String themeId) async {
    try {
      final model = await _remoteDatasource.unlockTheme(themeId);
      return Result.success(model.toEntity());
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to unlock theme: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> activateTheme(String themeId) async {
    try {
      await _remoteDatasource.activateTheme(themeId);
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to activate theme: ${e.toString()}'),
      );
    }
  }
}
