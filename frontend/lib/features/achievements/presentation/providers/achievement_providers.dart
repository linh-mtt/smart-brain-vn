import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/achievement_remote_datasource.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/achievement_repository_impl.dart';
import '../../domain/repositories/achievement_repository.dart';

/// Provides the [AchievementRemoteDatasource] instance.
final achievementRemoteDatasourceProvider =
    Provider<AchievementRemoteDatasource>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return AchievementRemoteDatasource(apiClient: apiClient);
    });

/// Provides the [AchievementRepository] implementation.
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepositoryImpl(
    remoteDatasource: ref.read(achievementRemoteDatasourceProvider),
  );
});

/// Fetches all achievements for the current user.
final achievementsProvider = FutureProvider<List<AchievementModel>>((
  ref,
) async {
  final datasource = ref.read(achievementRemoteDatasourceProvider);
  return datasource.getAchievements();
});
