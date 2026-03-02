import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../domain/entities/learning_tip_entity.dart';
import '../../domain/entities/quiz_question_entity.dart';
import '../../domain/entities/tip_step_entity.dart';
import '../notifiers/learning_tips_notifier.dart';
import '../providers/learning_tips_providers.dart';

/// Tip detail page with tutorial steps and interactive quiz.
class TipDetailPage extends ConsumerStatefulWidget {
  const TipDetailPage({super.key, required this.tipId});

  final String tipId;

  @override
  ConsumerState<TipDetailPage> createState() => _TipDetailPageState();
}

class _TipDetailPageState extends ConsumerState<TipDetailPage>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _shakeController = AnimationController(vsync: this, duration: 400.ms);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tipDetailProvider.notifier).loadTip(widget.tipId);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Color _parseTipColor(LearningTipEntity tip) {
    try {
      return Color(int.parse(tip.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tipDetailProvider);

    ref.listen<TipDetailState>(tipDetailProvider, (prev, next) {
      if (prev != null && !prev.quizCompleted && next.quizCompleted) {
        _confettiController.play();
      }
    });

    if (state.isLoading || state.tip == null) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(state.error!, style: AppTextStyles.body1),
              const SizedBox(height: 24),
              AnimatedButton(
                text: 'Try Again',
                onPressed: () {
                  ref.read(tipDetailProvider.notifier).loadTip(widget.tipId);
                },
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    final tip = state.tip!;

    if (state.quizCompleted) {
      return _QuizCompletedView(
        tip: tip,
        correctCount: state.correctCount,
        totalQuestions: state.totalQuestions,
        confettiController: _confettiController,
        tipColor: _parseTipColor(tip),
        onDone: () async {
          await ref.read(tipDetailProvider.notifier).completeQuiz();
          if (context.mounted) context.pop();
        },
      );
    }

    if (state.isQuizMode) {
      return _QuizModeView(
        tip: tip,
        state: state,
        tipColor: _parseTipColor(tip),
        shakeController: _shakeController,
        onSelectAnswer: (index) {
          ref.read(tipDetailProvider.notifier).selectAnswer(index);
        },
        onSubmit: () {
          final currentState = ref.read(tipDetailProvider);
          final question = tip.quizQuestions[currentState.currentQuizIndex];
          final isCorrect =
              currentState.selectedAnswerIndex == question.correctIndex;

          ref.read(tipDetailProvider.notifier).submitAnswer();

          if (!isCorrect) {
            _shakeController.forward(from: 0);
          }
        },
        onNext: () {
          ref.read(tipDetailProvider.notifier).nextQuestion();
        },
        onBack: () => context.pop(),
      );
    }

    return _TutorialModeView(
      tip: tip,
      state: state,
      tipColor: _parseTipColor(tip),
      onNext: () {
        ref.read(tipDetailProvider.notifier).nextStep();
      },
      onPrevious: () {
        ref.read(tipDetailProvider.notifier).previousStep();
      },
      onStartQuiz: () {
        ref.read(tipDetailProvider.notifier).startQuiz();
      },
      onBack: () => context.pop(),
    );
  }
}

// =============================================================================
// Tutorial Mode
// =============================================================================

class _TutorialModeView extends StatelessWidget {
  const _TutorialModeView({
    required this.tip,
    required this.state,
    required this.tipColor,
    required this.onNext,
    required this.onPrevious,
    required this.onStartQuiz,
    required this.onBack,
  });

  final LearningTipEntity tip;
  final TipDetailState state;
  final Color tipColor;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onStartQuiz;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final step = tip.steps[state.currentStepIndex];

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tip.title,
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: onBack,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Lottie animation
            SizedBox(
              height: 150,
              child: Lottie.asset(
                tip.animationAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(tip.icon, style: const TextStyle(fontSize: 64)),
                  );
                },
              ),
            ),

            // Step progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(state.totalSteps, (index) {
                  final isActive = index == state.currentStepIndex;
                  final isCompleted = index < state.currentStepIndex;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? tipColor
                            : isCompleted
                            ? tipColor.withValues(alpha: 0.4)
                            : AppColors.disabled,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Step ${state.currentStepIndex + 1} of ${state.totalSteps}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Step content with entrance animation
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _TutorialStepCard(
                  key: ValueKey(state.currentStepIndex),
                  step: step,
                  tipColor: tipColor,
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Previous button
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: state.currentStepIndex > 0 ? 1.0 : 0.4,
                      child: AnimatedButton(
                        text: 'Previous',
                        onPressed: state.currentStepIndex > 0
                            ? onPrevious
                            : null,
                        backgroundColor: AppColors.surface,
                        textColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Next / Start Quiz button
                  Expanded(
                    child: AnimatedButton(
                      text: state.isLastStep ? 'Start Quiz 🧠' : 'Next',
                      onPressed: state.isLastStep ? onStartQuiz : onNext,
                      backgroundColor: tipColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStepCard extends StatelessWidget {
  const _TutorialStepCard({
    super.key,
    required this.step,
    required this.tipColor,
  });

  final TipStepEntity step;
  final Color tipColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step title
        Text(
          step.title,
          style: AppTextStyles.heading3.copyWith(color: tipColor),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 12),

        // Content
        Text(step.content, style: AppTextStyles.body1)
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 16),

        // Example box
        Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tipColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: tipColor, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example',
                    style: AppTextStyles.caption.copyWith(
                      color: tipColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.example,
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),

        // Visual hint
        if (step.visualHint != null) ...[
          const SizedBox(height: 16),
          Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.visualHint!,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// =============================================================================
// Quiz Mode
// =============================================================================

class _QuizModeView extends StatelessWidget {
  const _QuizModeView({
    required this.tip,
    required this.state,
    required this.tipColor,
    required this.shakeController,
    required this.onSelectAnswer,
    required this.onSubmit,
    required this.onNext,
    required this.onBack,
  });

  final LearningTipEntity tip;
  final TipDetailState state;
  final Color tipColor;
  final AnimationController shakeController;
  final ValueChanged<int> onSelectAnswer;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final question = tip.quizQuestions[state.currentQuizIndex];

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Quiz — Q${state.currentQuizIndex + 1}/${state.totalQuestions}',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: onBack,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (state.currentQuizIndex + 1) / state.totalQuestions,
                  minHeight: 6,
                  backgroundColor: AppColors.disabled.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(tipColor),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question card
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: tipColor.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            question.question,
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        .animate(key: ValueKey(state.currentQuizIndex))
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                          duration: 400.ms,
                        ),

                    const SizedBox(height: 24),

                    // Answer options
                    ...List.generate(question.options.length, (index) {
                      return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuizAnswerCard(
                              option: question.options[index],
                              index: index,
                              isSelected: state.selectedAnswerIndex == index,
                              isCorrect:
                                  state.showExplanation &&
                                  index == question.correctIndex,
                              isWrong:
                                  state.showExplanation &&
                                  state.quizAnswers[state.currentQuizIndex] ==
                                      index &&
                                  index != question.correctIndex,
                              isDisabled: state.showExplanation,
                              tipColor: tipColor,
                              shakeController: shakeController,
                              onTap: state.showExplanation
                                  ? null
                                  : () => onSelectAnswer(index),
                            ),
                          )
                          .animate(
                            delay: (80 * index).ms,
                            key: ValueKey('${state.currentQuizIndex}_$index'),
                          )
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.1, end: 0);
                    }),

                    const SizedBox(height: 16),

                    // Submit / Next button
                    if (!state.showExplanation)
                      AnimatedButton(
                        text: 'Submit Answer',
                        onPressed: state.selectedAnswerIndex != null
                            ? onSubmit
                            : null,
                        backgroundColor: tipColor,
                        isEnabled: state.selectedAnswerIndex != null,
                      ),

                    // Explanation card
                    if (state.showExplanation) ...[
                      _ExplanationCard(
                        question: question,
                        selectedIndex:
                            state.quizAnswers[state.currentQuizIndex] ?? -1,
                        tipColor: tipColor,
                      ),
                      const SizedBox(height: 16),
                      AnimatedButton(
                        text: state.currentQuizIndex < state.totalQuestions - 1
                            ? 'Next Question →'
                            : 'See Results 🎉',
                        onPressed: onNext,
                        backgroundColor: tipColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizAnswerCard extends StatelessWidget {
  const _QuizAnswerCard({
    required this.option,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.isDisabled,
    required this.tipColor,
    required this.shakeController,
    required this.onTap,
  });

  final String option;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;
  final Color tipColor;
  final AnimationController shakeController;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.disabled;
    Color backgroundColor = Colors.white;
    Color textColor = AppColors.textPrimary;

    if (isCorrect) {
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
    } else if (isWrong) {
      borderColor = AppColors.error;
      backgroundColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
    } else if (isSelected) {
      borderColor = tipColor;
      backgroundColor = tipColor.withValues(alpha: 0.08);
      textColor = tipColor;
    }

    final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected || isCorrect || isWrong ? 2.5 : 1.5,
            ),
            boxShadow: isSelected || isCorrect
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Option label circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected || isCorrect || isWrong
                      ? borderColor.withValues(alpha: 0.15)
                      : AppColors.disabled.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCorrect
                      ? Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: AppColors.success,
                        )
                      : isWrong
                      ? Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.error,
                        )
                      : Text(
                          optionLabel,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? tipColor
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Apply shake animation for wrong answers
    if (isWrong) {
      card = AnimatedBuilder(
        animation: shakeController,
        builder: (context, child) {
          final shakeOffset =
              8.0 *
              sin(shakeController.value * pi * 4) *
              (1 - shakeController.value);
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: child,
          );
        },
        child: card,
      );
    }

    // Scale bounce for correct
    if (isCorrect) {
      card = card.animate().scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.03, 1.03),
        duration: 300.ms,
        curve: Curves.easeOutBack,
      );
    }

    return card;
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.question,
    required this.selectedIndex,
    required this.tipColor,
  });

  final QuizQuestionEntity question;
  final int selectedIndex;
  final Color tipColor;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selectedIndex == question.correctIndex;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCorrect
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCorrect
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: isCorrect ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? 'Correct! ✅' : 'Not quite! ❌',
                    style: AppTextStyles.heading4.copyWith(
                      color: isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.explanation,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }
}

// =============================================================================
// Quiz Completed
// =============================================================================

class _QuizCompletedView extends StatelessWidget {
  const _QuizCompletedView({
    required this.tip,
    required this.correctCount,
    required this.totalQuestions,
    required this.confettiController,
    required this.tipColor,
    required this.onDone,
  });

  final LearningTipEntity tip;
  final int correctCount;
  final int totalQuestions;
  final ConfettiController confettiController;
  final Color tipColor;
  final VoidCallback onDone;

  String get _message {
    final pct = totalQuestions > 0 ? correctCount / totalQuestions : 0;
    if (pct >= 1.0) return 'Perfect Score! 🌟';
    if (pct >= 0.7) return 'Great Job! 🎉';
    return 'Keep Practicing! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie success animation
                    SizedBox(
                      height: 180,
                      child: Lottie.asset(
                        AssetPaths.quizSuccessAnimation,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            '🎊',
                            style: const TextStyle(fontSize: 80),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Score
                    Text(
                      '$correctCount/$totalQuestions',
                      style: AppTextStyles.scoreDisplay.copyWith(
                        color: tipColor,
                      ),
                    ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                    const SizedBox(height: 16),

                    // Message
                    Text(
                          _message,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 8),

                    Text(
                      tip.title,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Done button
                    AnimatedButton(
                          text: 'Done',
                          onPressed: onDone,
                          backgroundColor: tipColor,
                          icon: Icons.check_rounded,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.success,
                  AppColors.warning,
                  Colors.purple,
                ],
                numberOfParticles: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
