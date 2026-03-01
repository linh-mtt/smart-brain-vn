import 'package:flutter/material.dart';

/// App color palette designed for kid-friendly, cheerful UI.
///
/// Colors are carefully chosen to be vibrant but not overwhelming,
/// with good contrast for readability.
abstract final class AppColors {
  // ─── Primary Colors ───────────────────────────────────────────────

  /// Vibrant blue - main brand color.
  static const Color primary = Color(0xFF4A90D9);

  /// Darker shade of primary for pressed states.
  static const Color primaryDark = Color(0xFF3A72B0);

  /// Lighter shade of primary for backgrounds.
  static const Color primaryLight = Color(0xFFB3D4F7);

  // ─── Secondary Colors ─────────────────────────────────────────────

  /// Playful orange - accent and CTA color.
  static const Color secondary = Color(0xFFFF6B35);

  /// Darker shade of secondary.
  static const Color secondaryDark = Color(0xFFE05A2A);

  /// Lighter shade of secondary.
  static const Color secondaryLight = Color(0xFFFFAA85);

  // ─── Semantic Colors ──────────────────────────────────────────────

  /// Success green.
  static const Color success = Color(0xFF4CAF50);

  /// Error red.
  static const Color error = Color(0xFFF44336);

  /// Warning amber.
  static const Color warning = Color(0xFFFF9800);

  /// Info blue.
  static const Color info = Color(0xFF2196F3);

  // ─── Neutral Colors ───────────────────────────────────────────────

  /// Background - light cream for a warm, inviting feel.
  static const Color background = Color(0xFFFFF8F0);

  /// Surface white.
  static const Color surface = Color(0xFFFFFFFF);

  /// Card background with slight warmth.
  static const Color card = Color(0xFFFFFDFA);

  /// Dark text.
  static const Color textPrimary = Color(0xFF2D3142);

  /// Medium text.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Light text / hint.
  static const Color textHint = Color(0xFF9CA3AF);

  /// Divider color.
  static const Color divider = Color(0xFFE5E7EB);

  /// Disabled state.
  static const Color disabled = Color(0xFFD1D5DB);

  // ─── Grade-Specific Colors ────────────────────────────────────────

  /// Color for Grade 1 (ages 6-7).
  static const Color grade1 = Color(0xFFFF6B6B);

  /// Color for Grade 2 (ages 7-8).
  static const Color grade2 = Color(0xFFFF9F43);

  /// Color for Grade 3 (ages 8-9).
  static const Color grade3 = Color(0xFFFECA57);

  /// Color for Grade 4 (ages 9-10).
  static const Color grade4 = Color(0xFF48DBFB);

  /// Color for Grade 5 (ages 10-11).
  static const Color grade5 = Color(0xFF5F27CD);

  /// Color for Grade 6 (ages 11-12).
  static const Color grade6 = Color(0xFF00D2D3);

  /// Returns the color associated with a grade level (1-6).
  static Color gradeColor(int grade) => switch (grade) {
    1 => grade1,
    2 => grade2,
    3 => grade3,
    4 => grade4,
    5 => grade5,
    6 => grade6,
    _ => primary,
  };

  /// Returns the name label for a grade level.
  static String gradeName(int grade) => switch (grade) {
    1 => 'Grade 1',
    2 => 'Grade 2',
    3 => 'Grade 3',
    4 => 'Grade 4',
    5 => 'Grade 5',
    6 => 'Grade 6',
    _ => 'Grade $grade',
  };

  // ─── Gradient Presets ─────────────────────────────────────────────

  /// Primary gradient for buttons and headers.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF6BB0F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient for accent elements.
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF8F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Background gradient for pages.
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Fun rainbow gradient for achievements.
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [grade1, grade2, grade3, grade4, grade5, grade6],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
