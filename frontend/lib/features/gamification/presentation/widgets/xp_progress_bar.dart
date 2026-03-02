import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated XP progress bar showing level progress.
///
/// Displays the user's current level, XP progress toward the next level,
/// and animates when XP changes.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.currentLevel,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
    required this.totalXp,
    this.height = 20,
    this.showLabel = true,
    this.animate = true,
  });

  /// Current user level.
  final int currentLevel;

  /// XP earned in the current level.
  final int xpInCurrentLevel;

  /// XP required for the next level.
  final int xpForNextLevel;

  /// Total accumulated XP.
  final int totalXp;

  /// Height of the progress bar.
  final double height;

  /// Whether to show the XP label text.
  final bool showLabel;

  /// Whether to animate the progress bar.
  final bool animate;

  double get _progress => xpForNextLevel > 0
      ? (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.$currentLevel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '⭐ $totalXp XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (showLabel)
              Text(
                '$xpInCurrentLevel / $xpForNextLevel XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
                // Filled portion
                Builder(builder: (context) {
                  final bar = FractionallySizedBox(
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.tertiary],
                        ),
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  );
                  if (!animate) return bar;
                  return bar.animate().scaleX(
                    begin: 0.0,
                    end: 1.0,
                    alignment: Alignment.centerLeft,
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  );
                }),
                // Shine effect
                if (_progress > 0.05)
                  Builder(builder: (context) {
                    final shine = FractionallySizedBox(
                      widthFactor: _progress,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 12,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    if (!animate) return shine;
                    return shine
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms, delay: 500.ms);
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
