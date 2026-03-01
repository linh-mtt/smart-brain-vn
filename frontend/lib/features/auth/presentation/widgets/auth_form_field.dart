import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';

/// A kid-friendly text form field with rounded borders and icon prefix.
///
/// Features:
/// - Rounded border (16dp radius)
/// - Icon prefix
/// - Animated error display
/// - Large touch target (56dp height)
/// - Clear visual feedback
class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofillHints,
    this.maxLength,
    this.enabled = true,
  });

  /// Text editing controller.
  final TextEditingController controller;

  /// Field label text.
  final String label;

  /// Placeholder hint text.
  final String? hint;

  /// Icon displayed at the start of the field.
  final IconData? prefixIcon;

  /// Widget displayed at the end of the field.
  final Widget? suffixIcon;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Keyboard type for the field.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Validation function.
  final String? Function(String?)? validator;

  /// Callback when the field is submitted.
  final void Function(String)? onFieldSubmitted;

  /// Focus node for the field.
  final FocusNode? focusNode;

  /// Autofill hints for the field.
  final Iterable<String>? autofillHints;

  /// Maximum character length.
  final int? maxLength;

  /// Whether the field is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          autofillHints: autofillHints,
          maxLength: maxLength,
          enabled: enabled,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 22) : null,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.05, end: 0, duration: 300.ms);
  }
}

/// A password field with visibility toggle.
class PasswordFormField extends StatefulWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      focusNode: widget.focusNode,
      autofillHints: const [AutofillHints.password],
      suffixIcon: IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 22,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    );
  }
}
