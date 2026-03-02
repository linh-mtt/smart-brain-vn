import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/xp_profile_entity.dart';

/// Animated popup overlay for newly unlocked achievement badges.
///
/// Displays a full-screen overlay with the badge emoji, name, and reward.
/// Auto-dismisses after a configurable duration.
class BadgePopupOverlay extends StatelessWidget {
  const BadgePopupOverlay({
    super.key,
    required this.achievement,
    this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 4),
    this.animate = true,
  });

  /// The achievement to display.
  final UnlockedAchievementEntity achievement;

  /// Callback when the popup is dismissed.
  final VoidCallback? onDismiss;

  /// Duration before auto-dismiss.
  final Duration autoDismissDuration;

  /// Whether to animate the popup.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Badge emoji
    Widget emojiWidget = Text(
      achievement.emoji,
      style: const TextStyle(fontSize: 72),
    );
    if (animate) {
      emojiWidget = emojiWidget.animate().scale(
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        duration: 600.ms,
        curve: Curves.elasticOut,
      );
    }

    // "Achievement Unlocked!" label
    Widget titleWidget = Text(
      'Achievement Unlocked!',
      style: theme.textTheme.titleLarge?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
    if (animate) {
      titleWidget = titleWidget
          .animate()
          .fadeIn(delay: 300.ms, duration: 400.ms)
          .slideY(begin: 0.3, end: 0, delay: 300.ms);
    }

    // Achievement name
    Widget nameWidget = Text(
      achievement.name,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
    if (animate) {
      nameWidget = nameWidget.animate().fadeIn(delay: 500.ms, duration: 400.ms);
    }

    // Description
    Widget descriptionWidget = Text(
      achievement.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
    if (animate) {
      descriptionWidget = descriptionWidget.animate().fadeIn(
        delay: 600.ms,
        duration: 400.ms,
      );
    }

    // Reward points
    Widget rewardWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '+${achievement.rewardPoints} XP',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (animate) {
      rewardWidget = rewardWidget
          .animate()
          .fadeIn(delay: 800.ms, duration: 400.ms)
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            delay: 800.ms,
          );
    }

    // Tap to dismiss hint
    Widget dismissHintWidget = Text(
      'Tap anywhere to dismiss',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
    if (animate) {
      dismissHintWidget = dismissHintWidget.animate().fadeIn(
        delay: 1200.ms,
        duration: 400.ms,
      );
    }

    // Card container
    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          emojiWidget,
          const SizedBox(height: 16),
          titleWidget,
          const SizedBox(height: 8),
          nameWidget,
          const SizedBox(height: 8),
          descriptionWidget,
          const SizedBox(height: 16),
          rewardWidget,
          const SizedBox(height: 16),
          dismissHintWidget,
        ],
      ),
    );
    if (animate) {
      card = card
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 300.ms);
    }

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: onDismiss,
        splashColor: Colors.transparent,
        child: Center(child: card),
      ),
    );
  }
}
