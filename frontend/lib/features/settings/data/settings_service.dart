import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';

/// Keys for settings stored in Hive.
abstract final class SettingsKeys {
  static const String soundEnabled = 'sound_enabled';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String darkModeEnabled = 'dark_mode_enabled';
  static const String language = 'language';
  static const String gradeLevel = 'grade_level';
}

/// Service for persisting user settings in Hive local storage.
///
/// Uses [HiveService.settingsBox] for all settings data.
/// All reads are synchronous after Hive init; writes are async.
class SettingsService {
  SettingsService({required HiveService hiveService})
    : _hiveService = hiveService;

  final HiveService _hiveService;

  // ─── Sound ──────────────────────────────────────────────────────────

  Future<bool> getSoundEnabled() async {
    final value = await _hiveService.getValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.soundEnabled,
    );
    return value as bool? ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _hiveService.putValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.soundEnabled,
      enabled,
    );
  }

  // ─── Notifications ──────────────────────────────────────────────────

  Future<bool> getNotificationsEnabled() async {
    final value = await _hiveService.getValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.notificationsEnabled,
    );
    return value as bool? ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _hiveService.putValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.notificationsEnabled,
      enabled,
    );
  }

  // ─── Dark Mode ──────────────────────────────────────────────────────

  Future<bool> getDarkModeEnabled() async {
    final value = await _hiveService.getValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.darkModeEnabled,
    );
    return value as bool? ?? false;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    await _hiveService.putValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.darkModeEnabled,
      enabled,
    );
  }

  // ─── Language ───────────────────────────────────────────────────────

  Future<String> getLanguage() async {
    final value = await _hiveService.getValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.language,
    );
    return value as String? ?? 'English';
  }

  Future<void> setLanguage(String language) async {
    await _hiveService.putValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.language,
      language,
    );
  }

  // ─── Grade Level ────────────────────────────────────────────────────

  Future<String> getGradeLevel() async {
    final value = await _hiveService.getValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.gradeLevel,
    );
    return value as String? ?? 'Grade 4';
  }

  Future<void> setGradeLevel(String gradeLevel) async {
    await _hiveService.putValue<dynamic>(
      HiveService.settingsBox,
      SettingsKeys.gradeLevel,
      gradeLevel,
    );
  }

  // ─── Reset ──────────────────────────────────────────────────────────

  /// Clears all settings back to defaults.
  Future<void> resetAll() async {
    await _hiveService.clearBox(HiveService.settingsBox);
  }

  /// Loads all settings at once. Used during initialization.
  Future<SettingsState> loadAll() async {
    final results = await Future.wait([
      getSoundEnabled(),
      getNotificationsEnabled(),
      getDarkModeEnabled(),
      getLanguage(),
      getGradeLevel(),
    ]);

    return SettingsState(
      soundEnabled: results[0] as bool,
      notificationsEnabled: results[1] as bool,
      darkModeEnabled: results[2] as bool,
      language: results[3] as String,
      gradeLevel: results[4] as String,
    );
  }
}

/// Immutable state for user settings.
class SettingsState {
  const SettingsState({
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'English',
    this.gradeLevel = 'Grade 4',
  });

  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String language;
  final String gradeLevel;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
    String? gradeLevel,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      gradeLevel: gradeLevel ?? this.gradeLevel,
    );
  }
}

/// Riverpod provider for [SettingsService].
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return SettingsService(hiveService: hiveService);
});
