import '../../../../core/errors/failures.dart';
import '../entities/leaderboard_entry_entity.dart';

/// Abstract repository defining leaderboard operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class LeaderboardRepository {
  /// Gets the leaderboard entries, optionally filtered by period.
  Future<Result<List<LeaderboardEntryEntity>>> getLeaderboard({String? period});
}
