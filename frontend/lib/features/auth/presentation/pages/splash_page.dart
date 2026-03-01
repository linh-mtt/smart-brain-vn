import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../notifiers/auth_notifier.dart';

/// Animated splash screen shown on app startup.
///
/// Displays the SmartMath Kids logo with animations,
/// checks authentication status, and routes accordingly.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Let the splash animation play for at least 2.5 seconds
    await Future.wait([
      ref.read(authNotifierProvider.notifier).checkAuthStatus(),
      Future<void>.delayed(const Duration(milliseconds: 2500)),
    ]);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    final isLoggedIn = authState.value != null;

    if (isLoggedIn) {
      context.go(RouteNames.homePath);
    } else {
      context.go(RouteNames.loginPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget lottieWidget = LottieBuilder.asset(
      AssetPaths.splashAnimation,
      width: 150,
      height: 150,
      fit: BoxFit.contain,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            // Floating math symbols background
            ..._buildFloatingSymbols(),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo icon
                  // Lottie animation logo
                  lottieWidget
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // App name
                  Text(
                        'SmartMath',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 36,
                          color: AppColors.primary,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 4),

                  // Tagline
                  Text(
                        'Kids',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  Text(
                    'Making Math Fun! ✨',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 48),

                  // Loading indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 1200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates floating math symbols for the background.
  List<Widget> _buildFloatingSymbols() {
    final symbols = [
      (symbol: '+', x: 0.1, y: 0.15, size: 28.0, delay: 0),
      (symbol: '−', x: 0.85, y: 0.1, size: 32.0, delay: 200),
      (symbol: '×', x: 0.15, y: 0.75, size: 26.0, delay: 400),
      (symbol: '÷', x: 0.8, y: 0.8, size: 30.0, delay: 600),
      (symbol: '=', x: 0.5, y: 0.08, size: 24.0, delay: 800),
      (symbol: '∑', x: 0.9, y: 0.45, size: 28.0, delay: 300),
      (symbol: 'π', x: 0.05, y: 0.45, size: 26.0, delay: 500),
      (symbol: '∞', x: 0.7, y: 0.92, size: 22.0, delay: 700),
    ];

    return symbols.map((s) {
      return Positioned(
        left: MediaQuery.sizeOf(context).width * s.x,
        top: MediaQuery.sizeOf(context).height * s.y,
        child:
            Text(
                  s.symbol,
                  style: TextStyle(
                    fontSize: s.size,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                )
                .animate(
                  delay: s.delay.ms,
                  onComplete: (controller) => controller.repeat(reverse: true),
                )
                .fadeIn(duration: 1000.ms)
                .moveY(
                  begin: 0,
                  end: -12,
                  duration: 2500.ms,
                  curve: Curves.easeInOut,
                ),
      );
    }).toList();
  }
}
