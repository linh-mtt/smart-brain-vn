import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/exercise_remote_datasource.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../notifiers/exercise_notifier.dart';

/// Provides the [ExerciseRemoteDatasource] instance.
final exerciseRemoteDatasourceProvider = Provider<ExerciseRemoteDatasource>((
  ref,
) {
  final apiClient = ref.read(apiClientProvider);
  return ExerciseRemoteDatasource(apiClient: apiClient);
});

/// Provides the [ExerciseRepository] implementation.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(
    remoteDatasource: ref.read(exerciseRemoteDatasourceProvider),
  );
});

/// The main exercise session state provider.
final exerciseSessionProvider =
    NotifierProvider.autoDispose<ExerciseSessionNotifier, ExerciseSessionState>(
      () => ExerciseSessionNotifier(),
    );
