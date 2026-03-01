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
import '../widgets/grade_selector.dart';

/// Registration page with multi-step form.
///
/// Step 1: Account info (email, username, password, confirm password)
/// Step 2: Grade selection (visual grade cards 1-6)
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();

  int _currentStep = 0;
  int? _selectedGrade;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = 0);
    }
  }

  Future<void> _handleRegister() async {
    if (_selectedGrade == null) {
      context.showErrorSnackBar('Please select a grade level');
      return;
    }

    final ageText = _ageController.text.trim();
    final ageError = Validators.age(ageText);
    if (ageError != null) {
      context.showErrorSnackBar(ageError);
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          gradeLevel: _selectedGrade!,
          age: int.parse(ageText),
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
        child: Column(
          children: [
            // App bar
            _buildAppBar(),

            // Step indicator
            _buildStepIndicator(),
            const Gap(8),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ResponsiveConstraint(
                  maxWidth: 480,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _currentStep == 0
                        ? _buildAccountInfoStep(key: const ValueKey(0))
                        : _buildGradeSelectionStep(
                            key: const ValueKey(1),
                            isLoading: isLoading,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep > 0 ? _previousStep : () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 28,
          ),
          const Spacer(),
          Text('Create Account', style: AppTextStyles.heading4),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          _StepDot(step: 0, currentStep: _currentStep, label: 'Account'),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                color: _currentStep >= 1
                    ? AppColors.primary
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _StepDot(step: 1, currentStep: _currentStep, label: 'Grade'),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildAccountInfoStep({Key? key}) {
    return Form(
      key: _formKey,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(16),

          // Header
          Text(
            'Let\'s Get Started! 🎉',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms),
          const Gap(8),
          Text(
            'Create your account to start learning',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          const Gap(32),

          // Email
          AuthFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            autofillHints: const [AutofillHints.email],
          ),
          const Gap(16),

          // Username
          AuthFormField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Choose a cool username',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: Validators.username,
            maxLength: 20,
            autofillHints: const [AutofillHints.username],
          ),
          const Gap(16),

          // Password
          PasswordFormField(
            controller: _passwordController,
            label: 'Password',
            hint: 'At least 8 characters',
            textInputAction: TextInputAction.next,
            validator: Validators.password,
          ),
          const Gap(16),

          // Confirm Password
          PasswordFormField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Type your password again',
            textInputAction: TextInputAction.done,
            validator: Validators.confirmPassword(_passwordController.text),
            onFieldSubmitted: (_) => _nextStep(),
          ),
          const Gap(32),

          // Next button
          SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: Text('Next Step →', style: AppTextStyles.buttonLarge),
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
          const Gap(24),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: AppTextStyles.body2),
              GestureDetector(
                onTap: () => context.go(RouteNames.loginPath),
                child: Text(
                  'Sign In',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildGradeSelectionStep({Key? key, required bool isLoading}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(16),

        // Header
        Text(
          'Almost There! 🎯',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 300.ms),
        const Gap(8),
        Text(
          'Tell us about yourself so we can personalize your experience',
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
        const Gap(24),

        // Age input
        AuthFormField(
          controller: _ageController,
          label: 'Your Age',
          hint: 'How old are you?',
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          validator: Validators.age,
          maxLength: 2,
        ),
        const Gap(24),

        // Grade selector
        GradeSelector(
          selectedGrade: _selectedGrade,
          onGradeSelected: (grade) {
            setState(() => _selectedGrade = grade);
          },
        ),
        const Gap(32),

        // Register button
        SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.secondary.withValues(alpha: 0.3),
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
                    : Text(
                        'Start Learning! 🚀',
                        style: AppTextStyles.buttonLarge,
                      ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0),
        const Gap(32),
      ],
    );
  }
}

/// Step indicator dot with label.
class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.currentStep,
    required this.label,
  });

  final int step;
  final int currentStep;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep >= step;
    final isCompleted = currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
