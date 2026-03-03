import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing Hive local storage operations.
///
/// Provides typed access to Hive boxes with error handling.
class HiveService {
  HiveService._();

  static final HiveService _instance = HiveService._();

  /// Singleton instance.
  static HiveService get instance => _instance;

  bool _isInitialized = false;

  /// Box names used throughout the app.
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  /// Initializes Hive with Flutter-specific configuration.
  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _isInitialized = true;
  }

  /// Opens a Hive box with the given [name].
  ///
  /// Always opens as dynamic to prevent type conflicts, then casts.
  Future<Box<T>> openBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name);
    }
    return Hive.box<dynamic>(name) as Box<T>;
  }

  /// Gets a value from the specified box.
  Future<T?> getValue<T>(String boxName, String key) async {
    final box = await openBox<T>(boxName);
    return box.get(key);
  }

  /// Puts a value into the specified box.
  Future<void> putValue<T>(String boxName, String key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  /// Deletes a value from the specified box.
  Future<void> deleteValue(String boxName, String key) async {
    final box = await openBox<dynamic>(boxName);
    await box.delete(key);
  }

  /// Clears all values in the specified box.
  Future<void> clearBox(String boxName) async {
    final box = await openBox<dynamic>(boxName);
    await box.clear();
  }

  /// Checks if a key exists in the specified box.
  Future<bool> hasKey(String boxName, String key) async {
    final box = await openBox<dynamic>(boxName);
    return box.containsKey(key);
  }

  /// Gets all values from a box.
  Future<List<T>> getAllValues<T>(String boxName) async {
    final box = await openBox<T>(boxName);
    return box.values.toList();
  }

  /// Closes all open Hive boxes.
  Future<void> closeAll() async {
    await Hive.close();
  }
}

/// Riverpod provider for [HiveService].
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService.instance;
});
