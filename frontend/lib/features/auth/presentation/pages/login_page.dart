import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;

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
  final _emailController = TextEditingController(text: 'linh.le@mttjsc.com');
  final _passwordController = TextEditingController(text: 'Linhlinh90');
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

    debugPrint('Starting login for: ${_emailController.text}');

    await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    debugPrint('Login action completed. Mounted: $mounted');

    if (!mounted) return;

    _checkAuthState();
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final account = await google.GoogleSignIn.instance.authenticate();

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        if (!mounted) return;
        context.showErrorSnackBar('Failed to get Google ID token');
        return;
      }

      await ref
          .read(authNotifierProvider.notifier)
          .googleLogin(idToken: idToken);

      if (!mounted) return;
      _checkAuthState();
    } catch (e) {
      if (!mounted) return;
      // TODO: Handle cancellation specifically (GoogleSignInExceptionCode.canceled)
      context.showErrorSnackBar('Google sign-in error: $e');
    }
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);
    debugPrint(
      'Checking auth state. HasValue: ${authState.hasValue}, IsError: ${authState.hasError}, Value: ${authState.value}',
    );
    if (authState.hasError) {
      final error = authState.error;
      final message = error is Failure
          ? error.displayMessage
          : 'Oops! Something went wrong. Let\'s try again!';
      context.showErrorSnackBar(message);
    } else if (authState.value != null) {
      debugPrint('Auth successful. Navigating to Home...');
      context.go(RouteNames.homePath);
    } else {
      debugPrint('Auth state value is null despite no error.');
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
                      onPressed: _handleGoogleLogin,
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
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 40,
            color: Colors.white,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(),
        const Gap(24),

        // Title
        Text(
          'Welcome Back! 👋',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const Gap(8),

        // Subtitle
        Text(
          'Let\'s continue your math adventure',
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Login',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to SmartMath?',
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.pushNamed(RouteNames.register),
          child: Text(
            'Create Account',
            style: AppTextStyles.button.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}
