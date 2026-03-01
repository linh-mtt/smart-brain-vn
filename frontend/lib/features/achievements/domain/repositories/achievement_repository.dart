import '../../../../core/errors/failures.dart';
import '../entities/achievement_entity.dart';

/// Abstract repository defining achievement operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class AchievementRepository {
  /// Gets all achievements for the current user.
  Future<Result<List<AchievementEntity>>> getAchievements();
}
