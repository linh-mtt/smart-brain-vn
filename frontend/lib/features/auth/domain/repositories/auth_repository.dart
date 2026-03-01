import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Authentication response containing user data and tokens.
class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserEntity user;
  final String accessToken;
  final String refreshToken;
}

/// Abstract repository defining authentication operations.
///
/// This contract is defined in the domain layer and implemented
/// in the data layer, following Clean Architecture principles.
abstract class AuthRepository {
  /// Logs in a user with email and password.
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  });

  /// Registers a new user account.
  Future<Result<AuthResponse>> register({
    required String email,
    required String username,
    required String password,
    required int gradeLevel,
    required int age,
  });

  /// Refreshes the authentication token.
  Future<Result<AuthResponse>> refreshToken({required String refreshToken});

  /// Logs out the current user.
  Future<Result<void>> logout();

  /// Gets the current user's profile.
  Future<Result<UserEntity>> getProfile();

  /// Updates the current user's profile.
  Future<Result<UserEntity>> updateProfile({
    String? displayName,
    String? avatarUrl,
    int? gradeLevel,
  });

  /// Checks if there are stored credentials and validates them.
  Future<Result<UserEntity>> checkAuthStatus();
}
