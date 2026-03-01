import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../notifiers/auth_notifier.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/social_login_button.dart';

/// Login page with email and password authentication.
///
/// Features:
/// - Email and password form fields with validation
/// - Animated button with loading state
/// - Social login placeholders
/// - Link to registration page
/// - Math-themed decorations
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      final error = authState.error;
      final message = error is Failure
          ? error.displayMessage
          : 'Oops! Something went wrong. Let\'s try again!';
      context.showErrorSnackBar(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return GradientBackground(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ResponsiveConstraint(
              maxWidth: 480,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Gap(24),

                    // Header
                    _buildHeader(),
                    const Gap(40),

                    // Email field
                    AuthFormField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      focusNode: _emailFocusNode,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const Gap(16),

                    // Password field
                    PasswordFormField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      focusNode: _passwordFocusNode,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const Gap(32),

                    // Login button
                    _buildLoginButton(isLoading),
                    const Gap(24),

                    // Divider
                    _buildDivider(),
                    const Gap(24),

                    // Social login buttons
                    SocialLoginButton(
                      provider: SocialProvider.google,
                      onPressed: () {
                        context.showSnackBar('Google sign-in coming soon! 🚀');
                      },
                    ),
                    const Gap(12),
                    SocialLoginButton(
                      provider: SocialProvider.apple,
                      onPressed: () {
                        context.showSnackBar('Apple sign-in coming soon! 🚀');
                      },
                    ),
                    const Gap(32),

                    // Register link
                    _buildRegisterLink(),
                    const Gap(24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🧮', style: TextStyle(fontSize: 40)),
              ),
            )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 400.ms),

        const Gap(24),

        Text(
              'Welcome Back! 👋',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),

        const Gap(8),

        Text(
          'Sign in to continue your math adventure',
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                : Text('Let\'s Go! 🚀', style: AppTextStyles.buttonLarge),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: AppTextStyles.body2.copyWith(color: AppColors.textHint),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 500.ms);
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Don\'t have an account? ', style: AppTextStyles.body2),
        GestureDetector(
          onTap: () => context.go(RouteNames.registerPath),
          child: Text(
            'Register',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 600.ms);
  }
}
