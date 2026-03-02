import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A toast notification showing XP gained.
///
/// Appears at the top of the screen and slides/fades away automatically.
class XpGainToast extends StatelessWidget {
  const XpGainToast({
    super.key,
    required this.xpAmount,
    this.comboMultiplier,
    this.animate = true,
  });

  /// Amount of XP gained.
  final int xpAmount;

  /// Optional combo multiplier (e.g., 2x, 3x).
  final int? comboMultiplier;

  /// Whether to animate the toast.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasCombo = comboMultiplier != null && comboMultiplier! > 1;

    Widget toast = Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            '+$xpAmount XP',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasCombo) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${comboMultiplier}x',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (animate) {
      toast = toast
          .animate()
          .slideY(
            begin: -1,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 300.ms)
          .then(delay: 2000.ms)
          .slideY(end: -1, duration: 300.ms, curve: Curves.easeIn)
          .fadeOut(duration: 300.ms);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(child: toast),
    );
  }
}
