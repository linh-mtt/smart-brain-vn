import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../notifiers/auth_notifier.dart';

/// Provides the [AuthRemoteDatasource] instance.
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRemoteDatasource(apiClient: apiClient);
});

/// Provides the [AuthLocalDatasource] instance.
final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return AuthLocalDatasource(hiveService: hiveService);
});

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.read(authRemoteDatasourceProvider),
    localDatasource: ref.read(authLocalDatasourceProvider),
    secureStorage: ref.read(secureStorageServiceProvider),
  );
});

/// Whether the user is currently logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value != null;
});

/// The current user (null if not logged in).
final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value;
});
