import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of [AuthRepository] that coordinates between
/// remote and local data sources.
///
/// Handles error mapping, token persistence, and user caching.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required AuthLocalDatasource localDatasource,
    required SecureStorageService secureStorage,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource,
       _secureStorage = secureStorage;

  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;
  final SecureStorageService _secureStorage;

  @override
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.login(
        email: email,
        password: password,
      );

      // Persist tokens securely
      await _secureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await _secureStorage.saveUserId(response.user.id);

      // Cache user locally
      await _localDatasource.cacheUser(response.user);

      return Result.success(
        AuthResponse(
          user: response.user.toEntity(),
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        ),
      );
    } on AppException catch (e) {
      return Result.failure(_mapException(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Login failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<AuthResponse>> register({
    required String email,
    required String username,
    required String password,
    required int gradeLevel,
    required int age,
  }) async {
    try {
      final response = await _remoteDatasource.register(
        email: email,
        username: username,
        password: password,
        gradeLevel: gradeLevel,
        age: age,
      );

      // Persist tokens securely
      await _secureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await _secureStorage.saveUserId(response.user.id);

      // Cache user locally
      await _localDatasource.cacheUser(response.user);

      return Result.success(
        AuthResponse(
          user: response.user.toEntity(),
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        ),
      );
    } on AppException catch (e) {
      return Result.failure(_mapException(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Registration failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<AuthResponse>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _remoteDatasource.refreshToken(
        refreshToken: refreshToken,
      );

      await _secureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      return Result.success(
        AuthResponse(
          user: response.user.toEntity(),
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        ),
      );
    } on AppException catch (e) {
      return Result.failure(_mapException(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Token refresh failed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Try to notify server (best effort)
      try {
        await _remoteDatasource.logout();
      } catch (_) {
        // Ignore server errors during logout - we clean up locally regardless
      }

      // Clear all local data
      await _secureStorage.deleteTokens();
      await _localDatasource.clearCache();

      return const Result.success(null);
    } catch (e) {
      // Even if local cleanup fails partially, consider logout successful
      return const Result.success(null);
    }
  }

  @override
  Future<Result<UserEntity>> getProfile() async {
    try {
      final userModel = await _remoteDatasource.getProfile();
      await _localDatasource.cacheUser(userModel);
      return Result.success(userModel.toEntity());
    } on AppException catch (e) {
      // Fallback to cached data on network errors
      if (e is NetworkException) {
        return _getCachedProfile();
      }
      return Result.failure(_mapException(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to get profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    String? displayName,
    String? avatarUrl,
    int? gradeLevel,
  }) async {
    try {
      final userModel = await _remoteDatasource.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
        gradeLevel: gradeLevel,
      );
      await _localDatasource.cacheUser(userModel);
      return Result.success(userModel.toEntity());
    } on AppException catch (e) {
      return Result.failure(_mapException(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to update profile: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<UserEntity>> checkAuthStatus() async {
    try {
      final hasTokens = await _secureStorage.hasTokens();
      if (!hasTokens) {
        return const Result.failure(
          AuthFailure(message: 'No stored credentials'),
        );
      }

      // Try to get profile from server to validate token
      final userModel = await _remoteDatasource.getProfile();
      await _localDatasource.cacheUser(userModel);
      return Result.success(userModel.toEntity());
    } on AppException catch (e) {
      // If server is unreachable, try cached data
      if (e is NetworkException) {
        return _getCachedProfile();
      }
      // Token might be expired
      if (e is AuthException || e is TokenExpiredException) {
        await _secureStorage.deleteTokens();
        await _localDatasource.clearCache();
      }
      return Result.failure(_mapException(e));
    } catch (e) {
      return Result.failure(
        UnknownFailure(message: 'Failed to check auth status: ${e.toString()}'),
      );
    }
  }

  /// Attempts to return cached profile data.
  Future<Result<UserEntity>> _getCachedProfile() async {
    try {
      final cachedUser = await _localDatasource.getCachedUser();
      if (cachedUser != null) {
        return Result.success(cachedUser.toEntity());
      }
      return const Result.failure(
        CacheFailure(message: 'No cached user data available'),
      );
    } catch (_) {
      return const Result.failure(
        CacheFailure(message: 'Failed to read cached data'),
      );
    }
  }

  /// Maps application exceptions to domain failures.
  Failure _mapException(AppException exception) {
    return switch (exception) {
      ServerException(:final message, :final statusCode) => ServerFailure(
        message: message,
        statusCode: statusCode,
      ),
      CacheException(:final message, :final statusCode) => CacheFailure(
        message: message,
        statusCode: statusCode,
      ),
      NetworkException(:final message, :final statusCode) => NetworkFailure(
        message: message,
        statusCode: statusCode,
      ),
      AuthException(:final message, :final statusCode) => AuthFailure(
        message: message,
        statusCode: statusCode,
      ),
      TokenExpiredException(:final message, :final statusCode) => AuthFailure(
        message: message,
        statusCode: statusCode,
      ),
    };
  }
}
