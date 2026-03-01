import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

/// Root widget for SmartMath Kids.
///
/// Uses [ConsumerWidget] to access Riverpod providers for
/// routing (GoRouter) and theme configuration.
class SmartMathApp extends ConsumerWidget {
  const SmartMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SmartMath Kids',
      debugShowCheckedModeBanner: false,

      // ─── Theme ───────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // ─── Router ──────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}
