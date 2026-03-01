import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// A centered loading indicator with optional message.
///
/// Features a shimmer effect for a polished, kid-friendly appearance.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message, this.size = 48.0, this.color});

  /// Optional message to display below the spinner.
  final String? message;

  /// Size of the loading indicator.
  final double size;

  /// Color of the loading indicator.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primary,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Shimmer.fromColors(
              baseColor: AppColors.textSecondary,
              highlightColor: AppColors.primary,
              child: Text(
                message!,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A loading shimmer placeholder for list items.
class AppLoadingShimmer extends StatelessWidget {
  const AppLoadingShimmer({super.key, this.itemCount = 3, this.height = 80});

  /// Number of shimmer items to display.
  final int itemCount;

  /// Height of each shimmer item.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
