import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A scaffold wrapper that provides a gradient background.
///
/// Wraps content in a [Scaffold] with a configurable gradient
/// background, defaulting to the app's warm cream-to-white gradient.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  /// The main content widget.
  final Widget child;

  /// Custom gradient (defaults to AppColors.backgroundGradient).
  final Gradient? gradient;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Whether to resize when keyboard appears.
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.backgroundGradient,
        ),
        child: child,
      ),
    );
  }
}
