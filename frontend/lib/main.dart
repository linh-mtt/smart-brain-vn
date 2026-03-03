import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';
import 'config/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration (.env files with priority ordering)
  await EnvConfig.load();

  // Lock orientation to portrait for kid-friendly experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive for local storage
  await HiveService.instance.init();

  // Open required Hive boxes
  await Future.wait([
    HiveService.instance.openBox<dynamic>(HiveService.userBox),
    HiveService.instance.openBox<dynamic>(HiveService.settingsBox),
    HiveService.instance.openBox<dynamic>(HiveService.cacheBox),
  ]);

  runApp(const ProviderScope(child: SmartMathApp()));
}
