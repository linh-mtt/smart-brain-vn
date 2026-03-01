import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/progress_remote_datasource.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../domain/repositories/progress_repository.dart';
import '../notifiers/progress_notifier.dart';

/// Provides the [ProgressRemoteDatasource] instance.
final progressRemoteDatasourceProvider = Provider<ProgressRemoteDatasource>((
  ref,
) {
  final apiClient = ref.read(apiClientProvider);
  return ProgressRemoteDatasource(apiClient: apiClient);
});

/// Provides the [ProgressRepository] implementation.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepositoryImpl(
    remoteDatasource: ref.read(progressRemoteDatasourceProvider),
  );
});

/// Provides the [ProgressNotifier] for managing progress state.
final progressNotifierProvider =
    NotifierProvider<ProgressNotifier, ProgressState>(
      () => ProgressNotifier(),
    );
