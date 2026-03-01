import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// An animated button with gradient background, press feedback, and loading state.
///
/// Features:
/// - Scale-down on press with bounce-back animation
/// - Gradient background (customizable)
/// - Loading state with spinner
/// - Rounded corners (16dp)
/// - Minimum height of 56dp for kid-friendly touch targets
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width = double.infinity,
    this.height = 56,
    this.borderRadius = 16,
    this.textStyle,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Button label text.
  final String text;

  /// Whether the button shows a loading spinner.
  final bool isLoading;

  /// Whether the button is enabled.
  final bool isEnabled;

  /// Custom gradient background.
  final Gradient? gradient;

  /// Solid background color (used when gradient is null).
  final Color? backgroundColor;

  /// Text color override.
  final Color? textColor;

  /// Optional leading icon.
  final IconData? icon;

  /// Button width.
  final double width;

  /// Button height.
  final double height;

  /// Border radius.
  final double borderRadius;

  /// Custom text style.
  final TextStyle? textStyle;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isInteractive =>
      widget.isEnabled && !widget.isLoading && widget.onPressed != null;

  void _handleTapDown(TapDownDetails details) {
    if (_isInteractive) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isInteractive) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ?? AppColors.primaryGradient;
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _isInteractive ? widget.onPressed : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isInteractive ? 1.0 : 0.5,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: widget.backgroundColor == null
                      ? effectiveGradient
                      : null,
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: _isInteractive
                      ? [
                          BoxShadow(
                            color: (widget.backgroundColor ?? AppColors.primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: effectiveTextColor,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: effectiveTextColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.text,
                              style: (widget.textStyle ?? AppTextStyles.button)
                                  .copyWith(color: effectiveTextColor),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        )
        .animate(target: _isInteractive ? 1 : 0)
        .shimmer(
          duration: 2000.ms,
          delay: 1000.ms,
          color: Colors.white.withValues(alpha: 0.1),
        );
  }
}
