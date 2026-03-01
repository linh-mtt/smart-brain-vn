import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/practice_remote_datasource.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/repositories/practice_repository.dart';
import '../notifiers/practice_notifier.dart';

/// Provides the [PracticeRemoteDatasource] instance.
final practiceRemoteDatasourceProvider = Provider<PracticeRemoteDatasource>((
  ref,
) {
  final apiClient = ref.read(apiClientProvider);
  return PracticeRemoteDatasource(apiClient: apiClient);
});

/// Provides the [PracticeRepository] instance.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepositoryImpl(
    remoteDatasource: ref.read(practiceRemoteDatasourceProvider),
  );
});

/// Provides the practice session state and notifier.
final practiceSessionProvider =
    NotifierProvider.autoDispose<PracticeSessionNotifier, PracticeSessionState>(
      () => PracticeSessionNotifier(),
    );
