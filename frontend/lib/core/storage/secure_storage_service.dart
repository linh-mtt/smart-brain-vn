import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like tokens.
///
/// Wraps [FlutterSecureStorage] with typed methods for common operations.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  // ─── Storage Keys ─────────────────────────────────────────────────

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _tokenExpiryKey = 'token_expiry';

  // ─── Access Token ─────────────────────────────────────────────────

  /// Saves the access token.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Retrieves the access token, or null if not stored.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  // ─── Refresh Token ────────────────────────────────────────────────

  /// Saves the refresh token.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieves the refresh token, or null if not stored.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  // ─── Token Expiry ─────────────────────────────────────────────────

  /// Saves the token expiry timestamp.
  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
  }

  /// Retrieves the token expiry timestamp.
  Future<DateTime?> getTokenExpiry() async {
    final value = await _storage.read(key: _tokenExpiryKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Checks if the stored token is expired.
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  // ─── User ID ──────────────────────────────────────────────────────

  /// Saves the current user's ID.
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Retrieves the current user's ID.
  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  // ─── Bulk Operations ──────────────────────────────────────────────

  /// Saves all authentication tokens at once.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Deletes all stored tokens and user data.
  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenExpiryKey),
      _storage.delete(key: _userIdKey),
    ]);
  }

  /// Deletes all stored data.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Checks if the user has stored tokens (potentially logged in).
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
