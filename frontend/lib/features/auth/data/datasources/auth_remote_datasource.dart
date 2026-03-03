import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Remote data source for authentication operations.
///
/// Communicates with the backend API via [ApiClient].
class AuthRemoteDatasource {
  AuthRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Logs in with email and password.
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _apiClient.post<AuthResponseModel>(
        ApiConstants.loginEndpoint,
        data: {'email': email, 'password': password},
        fromJson: _parseAuthResponse,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  /// Logs in with Google ID Token.
  Future<AuthResponseModel> googleLogin({required String idToken}) async {
    try {
      return await _apiClient.post<AuthResponseModel>(
        ApiConstants.googleLoginEndpoint,
        data: {'id_token': idToken},
        fromJson: _parseAuthResponse,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Google login failed: ${e.toString()}');
    }
  }

  /// Registers a new user account.
  Future<AuthResponseModel> register({
    required String email,
    required String username,
    required String password,
    required int gradeLevel,
    required int age,
  }) async {
    try {
      return await _apiClient.post<AuthResponseModel>(
        ApiConstants.registerEndpoint,
        data: {
          'email': email,
          'username': username,
          'password': password,
          'grade_level': gradeLevel,
          'age': age,
        },
        fromJson: _parseAuthResponse,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  /// Refreshes the authentication token.
  Future<AuthResponseModel> refreshToken({required String refreshToken}) async {
    try {
      return await _apiClient.post<AuthResponseModel>(
        ApiConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
        fromJson: _parseAuthResponse,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Token refresh failed: ${e.toString()}');
    }
  }

  AuthResponseModel _parseAuthResponse(dynamic json) {
    // Defensive coding: Ensure refresh_token exists
    if (json is Map<String, dynamic>) {
      if (!json.containsKey('refresh_token') || json['refresh_token'] == null) {
        // ignore: avoid_print
        print(
          '⚠️ Missing refresh_token in response. Defaulting to empty string.',
        );
        json['refresh_token'] = '';
      }
    }

    try {
      return AuthResponseModel.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      // ignore: avoid_print
      print('🐛 AuthRemoteDatasource Parse Error: $e');
      rethrow;
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      await _apiClient.post<dynamic>(ApiConstants.logoutEndpoint);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Logout failed: ${e.toString()}');
    }
  }

  /// Gets the current user's profile.
  Future<UserModel> getProfile() async {
    try {
      return await _apiClient.get<UserModel>(
        ApiConstants.profileEndpoint,
        fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get profile: ${e.toString()}');
    }
  }

  /// Updates the current user's profile.
  Future<UserModel> updateProfile({
    String? displayName,
    String? avatarUrl,
    int? gradeLevel,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (gradeLevel != null) data['grade_level'] = gradeLevel;

    try {
      return await _apiClient.put<UserModel>(
        ApiConstants.updateProfileEndpoint,
        data: data,
        fromJson: (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }
}
