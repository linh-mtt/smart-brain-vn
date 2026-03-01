import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for easy access to theme and media query.
extension ContextExtensions on BuildContext {
  // ─── Theme ────────────────────────────────────────────────────────

  /// Access the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Access the current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Access the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ─── Media Query ──────────────────────────────────────────────────

  /// Access the current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Screen padding (safe area).
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Whether the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Whether the screen width qualifies as tablet (>= 600dp).
  bool get isTablet => screenWidth >= 600;

  /// Whether the screen width qualifies as desktop (>= 900dp).
  bool get isDesktop => screenWidth >= 900;

  // ─── Navigation ───────────────────────────────────────────────────

  /// Show a snackbar with the given [message].
  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          action: action,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  /// Show an error snackbar.
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.error);
  }

  /// Show a success snackbar.
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: const Color(0xFF4CAF50));
  }
}
