import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'animated_button.dart';

/// Displays an error state with an illustration, message, and retry button.
///
/// Uses kid-friendly language and colorful design to soften error states.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
            const Gap(24),
            Text(
              'Oops! 😅',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              message,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const Gap(24),
              AnimatedButton(
                text: 'Try Again 🔄',
                onPressed: onRetry,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
