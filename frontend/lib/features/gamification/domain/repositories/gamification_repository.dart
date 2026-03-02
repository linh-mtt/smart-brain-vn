import '../../../../core/errors/failures.dart';
import '../entities/xp_profile_entity.dart';

/// Abstract repository defining gamification operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class GamificationRepository {
  /// Gets the current user's XP profile.
  Future<Result<XpProfileEntity>> getXpProfile();

  /// Gets all available themes with unlock status.
  Future<Result<List<ThemeEntity>>> getThemes();

  /// Unlocks a theme by ID.
  Future<Result<ThemeEntity>> unlockTheme(String themeId);

  /// Activates a theme by ID.
  Future<Result<void>> activateTheme(String themeId);
}
