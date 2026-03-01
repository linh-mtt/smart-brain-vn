import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/user_model.dart';

/// Local data source for caching authentication data.
///
/// Uses [HiveService] to persist user data locally.
class AuthLocalDatasource {
  AuthLocalDatasource({required HiveService hiveService})
    : _hiveService = hiveService;

  final HiveService _hiveService;

  static const String _cachedUserKey = 'cached_user';

  /// Caches the user model locally.
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonString = json.encode(user.toJson());
      await _hiveService.putValue<String>(
        HiveService.userBox,
        _cachedUserKey,
        jsonString,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache user: ${e.toString()}');
    }
  }

  /// Retrieves the cached user model.
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = await _hiveService.getValue<String>(
        HiveService.userBox,
        _cachedUserKey,
      );

      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      throw CacheException(
        message: 'Failed to get cached user: ${e.toString()}',
      );
    }
  }

  /// Clears all cached authentication data.
  Future<void> clearCache() async {
    try {
      await _hiveService.clearBox(HiveService.userBox);
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: ${e.toString()}');
    }
  }
}
