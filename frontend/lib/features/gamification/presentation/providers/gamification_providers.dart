import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/gamification_remote_datasource.dart';
import '../../data/repositories/gamification_repository_impl.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../notifiers/gamification_notifier.dart';

/// Provides the [GamificationRemoteDatasource] instance.
final gamificationRemoteDatasourceProvider =
    Provider<GamificationRemoteDatasource>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return GamificationRemoteDatasource(apiClient: apiClient);
    });

/// Provides the [GamificationRepository] implementation.
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(
    remoteDatasource: ref.read(gamificationRemoteDatasourceProvider),
  );
});

/// Provides the [GamificationNotifier] for state management.
final gamificationNotifierProvider =
    NotifierProvider<GamificationNotifier, GamificationState>(() {
      return GamificationNotifier();
    });
