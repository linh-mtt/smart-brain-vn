import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/leaderboard_remote_datasource.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// Provides the [LeaderboardRemoteDatasource] instance.
final leaderboardRemoteDatasourceProvider =
    Provider<LeaderboardRemoteDatasource>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return LeaderboardRemoteDatasource(apiClient: apiClient);
    });

/// Provides the [LeaderboardRepository] implementation.
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(
    remoteDatasource: ref.read(leaderboardRemoteDatasourceProvider),
  );
});

/// Notifier for the currently selected leaderboard period.
class LeaderboardPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'weekly';

  void setPeriod(String period) {
    state = period;
  }
}

/// Provider for the currently selected leaderboard period.
final leaderboardPeriodProvider =
    NotifierProvider<LeaderboardPeriodNotifier, String>(
      LeaderboardPeriodNotifier.new,
    );

/// Fetches leaderboard entries for the selected period.
final leaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((
  ref,
) async {
  final datasource = ref.read(leaderboardRemoteDatasourceProvider);
  final period = ref.watch(leaderboardPeriodProvider);
  return datasource.getLeaderboard(period: period);
});
