import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';

/// A placeholder social login button for future OAuth integration.
///
/// Supports Google and Apple sign-in button styles.
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  /// The social login provider.
  final SocialProvider provider;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in loading state.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final config = _providerConfig;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: config.backgroundColor,
          foregroundColor: config.textColor,
          side: BorderSide(color: config.borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: config.textColor,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(config.icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    config.label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: config.textColor,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  _SocialConfig get _providerConfig => switch (provider) {
    SocialProvider.google => const _SocialConfig(
      icon: Icons.g_mobiledata_rounded,
      label: 'Continue with Google',
      backgroundColor: Colors.white,
      textColor: AppColors.textPrimary,
      borderColor: AppColors.divider,
    ),
    SocialProvider.apple => const _SocialConfig(
      icon: Icons.apple_rounded,
      label: 'Continue with Apple',
      backgroundColor: Colors.black,
      textColor: Colors.white,
      borderColor: Colors.black,
    ),
  };
}

/// Supported social login providers.
enum SocialProvider { google, apple }

class _SocialConfig {
  const _SocialConfig({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
}
