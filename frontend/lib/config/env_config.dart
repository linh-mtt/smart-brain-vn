import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loader with multi-file priority support.
///
/// Priority order (highest to lowest):
/// 1. .env.[mode].local  (git-ignored, personal overrides)
/// 2. .env.[mode]        (environment-specific defaults)
/// 3. .env.local         (git-ignored, shared local overrides)
/// 4. .env               (base defaults)
abstract final class EnvConfig {
  /// Load environment files with priority ordering.
  ///
  /// [mode] is determined by the APP_ENV build-time define.
  /// Defaults to 'development' if not specified.
  static Future<void> load() async {
    const mode = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );

    // Load base .env first (lowest priority)
    try {
      await dotenv.load(fileName: '.env', isOptional: true);
    } catch (e) {
      // Ignore if .env file is missing
      debugPrint('[EnvConfig] .env file not found or failed to load: $e');
    }

    // Override with higher-priority files (last loaded wins)
    // Order: .env.local → .env.[mode] → .env.[mode].local
    final overrideFiles = [
      '.env.local',
      '.env.$mode',
      '.env.$mode.local',
    ];

    for (final file in overrideFiles) {
      await _mergeEnvFile(file);
    }

    if (kDebugMode) {
      debugPrint('[EnvConfig] Loaded environment: $mode');
      debugPrint(
        '[EnvConfig] API_BASE_URL: ${get('API_BASE_URL', fallback: 'not set')}',
      );
    }
  }

  /// Merge an env file into the existing env map, overriding duplicates.
  static Future<void> _mergeEnvFile(String fileName) async {
    try {
      final content = await rootBundle.loadString(fileName);
      if (content.isEmpty) return;
      final lines = content.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eqIndex = trimmed.indexOf('=');
        if (eqIndex <= 0) continue;
        final key = trimmed.substring(0, eqIndex).trim();
        final value = trimmed.substring(eqIndex + 1).trim();
        dotenv.env[key] = value;
      }
    } on FlutterError {
      // File not found in assets — silently skip optional env files.
    }
  }

  /// Get a required environment variable.
  static String get(String key, {String fallback = ''}) {
    return dotenv.get(key, fallback: fallback);
  }

  /// Get an optional environment variable.
  static String? maybeGet(String key) {
    return dotenv.maybeGet(key);
  }

  /// Get an environment variable as int.
  static int getInt(String key, {int fallback = 0}) {
    final value = dotenv.maybeGet(key);
    if (value == null) return fallback;
    return int.tryParse(value) ?? fallback;
  }

  /// Get an environment variable as bool.
  static bool getBool(String key, {bool fallback = false}) {
    final value = dotenv.maybeGet(key);
    if (value == null) return fallback;
    return value.toLowerCase() == 'true' || value == '1';
  }

  /// Check if all given keys are defined.
  static bool isEveryDefined(List<String> keys) {
    return dotenv.isEveryDefined(keys);
  }
}
