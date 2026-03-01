import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_service.dart';

/// Notifier that manages settings state with Hive persistence.
///
/// Loads settings from Hive on initialization, and persists every
/// change immediately. The state drives the entire app's settings
/// including theme mode.
class SettingsNotifier extends Notifier<SettingsState> {
  late final SettingsService _settingsService;

  @override
  SettingsState build() {
    _settingsService = ref.read(settingsServiceProvider);
    _loadSettings();
    return const SettingsState();
  }


  Future<void> _loadSettings() async {
    state = await _settingsService.loadAll();
  }

  Future<void> toggleSound(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _settingsService.setSoundEnabled(enabled);
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _settingsService.setNotificationsEnabled(enabled);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    state = state.copyWith(darkModeEnabled: enabled);
    await _settingsService.setDarkModeEnabled(enabled);
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _settingsService.setLanguage(language);
  }

  Future<void> setGradeLevel(String gradeLevel) async {
    state = state.copyWith(gradeLevel: gradeLevel);
    await _settingsService.setGradeLevel(gradeLevel);
  }

  Future<void> resetAll() async {
    await _settingsService.resetAll();
    state = const SettingsState();
  }
}

/// Main settings state provider.
///
/// Usage:
/// ```dart
/// final settings = ref.watch(settingsProvider);
/// final isDark = settings.darkModeEnabled;
/// ref.read(settingsProvider.notifier).toggleDarkMode(true);
/// ```
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Derived provider for theme mode only — prevents unnecessary rebuilds
/// when non-theme settings change.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final isDark = ref.watch(settingsProvider.select((s) => s.darkModeEnabled));
  return isDark ? ThemeMode.dark : ThemeMode.light;
});

/// Derived provider for sound setting.
final soundEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.soundEnabled));
});

/// Derived provider for notifications setting.
final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
});
