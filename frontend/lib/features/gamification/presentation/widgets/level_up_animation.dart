import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

/// Animated overlay for level-up celebrations.
///
/// Shows a Lottie celebration animation with the new level number.
/// Auto-dismisses after the animation completes.
class LevelUpAnimation extends StatelessWidget {
  const LevelUpAnimation({
    super.key,
    required this.newLevel,
    this.onComplete,
    this.animate = true,
  });

  /// The new level the user reached.
  final int newLevel;

  /// Callback when the animation completes.
  final VoidCallback? onComplete;

  /// Whether to animate the overlay.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Star icon
    Widget starWidget = const Text('🌟', style: TextStyle(fontSize: 56));
    if (animate) {
      starWidget = starWidget
          .animate()
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.elasticOut,
          )
          .rotate(begin: -0.1, end: 0, duration: 600.ms);
    }

    // "Level Up!" text
    Widget levelUpText = Text(
      'LEVEL UP!',
      style: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
    if (animate) {
      levelUpText = levelUpText
          .animate()
          .fadeIn(delay: 200.ms, duration: 400.ms)
          .slideY(begin: 0.5, end: 0, delay: 200.ms);
    }

    // Level number badge
    Widget levelBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        'Level $newLevel',
        style: theme.textTheme.headlineLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (animate) {
      levelBadge = levelBadge
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            delay: 400.ms,
            duration: 500.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(delay: 400.ms, duration: 300.ms);
    }

    // Tap to continue
    Widget tapText = Text(
      'Tap to continue',
      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
    );
    if (animate) {
      tapText = tapText.animate().fadeIn(delay: 1000.ms, duration: 400.ms);
    }

    // Lottie background (only when animating — asset may not exist in tests)
    Widget lottieWidget = animate
        ? Lottie.asset(
            'assets/animations/celebration.json',
            width: 300,
            height: 300,
            repeat: false,
            onLoaded: (composition) {
              // Auto-dismiss after animation
              Future.delayed(composition.duration + 500.ms, () {
                onComplete?.call();
              });
            },
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          )
        : const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: onComplete,
        splashColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lottie celebration background
            lottieWidget,
            // Level-up content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                starWidget,
                const SizedBox(height: 16),
                levelUpText,
                const SizedBox(height: 12),
                levelBadge,
                const SizedBox(height: 24),
                tapText,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
