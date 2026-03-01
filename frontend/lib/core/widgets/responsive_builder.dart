import 'package:flutter/material.dart';

/// Breakpoints for responsive layout.
abstract final class Breakpoints {
  /// Mobile max width.
  static const double mobile = 599;

  /// Tablet max width.
  static const double tablet = 899;
}

/// Builder that adapts layout based on screen size.
///
/// Provides separate builders for mobile and tablet layouts,
/// making it easy to create responsive UIs.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.mobile, this.tablet});

  /// Widget builder for mobile layout (< 600dp).
  final Widget mobile;

  /// Widget builder for tablet layout (>= 600dp).
  /// Falls back to [mobile] if not provided.
  final Widget? tablet;

  /// Returns true if current screen width is tablet or larger.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width > Breakpoints.mobile;
  }

  /// Returns true if current screen width is desktop or larger.
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width > Breakpoints.tablet;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width > Breakpoints.mobile && tablet != null) {
      return tablet!;
    }

    return mobile;
  }
}

/// Provides responsive padding based on screen size.
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = const EdgeInsets.symmetric(horizontal: 16),
    this.tabletPadding = const EdgeInsets.symmetric(horizontal: 32),
  });

  final Widget child;
  final EdgeInsets mobilePadding;
  final EdgeInsets tabletPadding;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBuilder.isTablet(context);
    return Padding(
      padding: isTablet ? tabletPadding : mobilePadding,
      child: child,
    );
  }
}

/// Constrains content width on larger screens.
class ResponsiveConstraint extends StatelessWidget {
  const ResponsiveConstraint({
    super.key,
    required this.child,
    this.maxWidth = 600,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
