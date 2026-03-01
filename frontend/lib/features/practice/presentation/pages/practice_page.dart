import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/router/route_names.dart';
import '../notifiers/practice_notifier.dart';
import '../providers/practice_providers.dart';
import '../../data/models/session_feedback_model.dart';

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({required this.topic, this.questionCount = 5, super.key});
  final String topic;
  final int questionCount;

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage>
    with TickerProviderStateMixin {
  late AnimationController _feedbackController;
  late AnimationController _timerController;
  late AnimationController _comboController;
  late AnimationController _shakeController;
  late ConfettiController _confettiController;

  int _selectedAnswer = -1;
  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: 600.ms);
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _comboController = AnimationController(vsync: this, duration: 400.ms);
    _shakeController = AnimationController(vsync: this, duration: 400.ms);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _timerController.addListener(_onTimerTick);

    Future.microtask(() {
      ref
          .read(practiceSessionProvider.notifier)
          .startSession(widget.topic, questionCount: widget.questionCount);
    });
  }

  void _onTimerTick() {
    if (!mounted) return;

    // Check if timer finished
    if (_timerController.isCompleted && !_answered) {
      // Time's up! Mark as wrong or just move next?
      // For now, let's treat it as a wrong answer (no selection)
      _onTimeExpired();
    }
  }

  void _onTimeExpired() {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedAnswer = -1; // No selection
      _isCorrect = false;
    });

    // Submit answer with 0 or some indicator of timeout?
    // The notifier expects a double answer. If we don't have one, we can't really submit.
    // But we should probably advance.
    // Let's force a wrong submission if possible, or just nextQuestion.
    // Submitting a likely wrong answer:
    ref
        .read(practiceSessionProvider.notifier)
        .submitAnswer(double.negativeInfinity);
  }

  void _startTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  void _selectAnswer(int index, double value) {
    if (_answered) return;

    _timerController.stop();

    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });

    ref.read(practiceSessionProvider.notifier).submitAnswer(value);
  }

  void _onFeedbackReceived(SessionFeedbackModel feedback) {
    setState(() => _isCorrect = feedback.isCorrect);

    if (feedback.isCorrect) {
      _confettiController.play();
      _feedbackController.forward();
      if (feedback.comboCount >= 3) {
        _comboController.forward(from: 0);
      }
    } else {
      _shakeController.forward(from: 0);
      _feedbackController.forward();
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    ref.read(practiceSessionProvider.notifier).nextQuestion();

    final state = ref.read(practiceSessionProvider);
    if (!state.isCompleted) {
      setState(() {
        _selectedAnswer = -1;
        _answered = false;
        _isCorrect = false;
      });
      _feedbackController.reset();
      _comboController.reset();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _timerController.dispose();
    _comboController.dispose();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practiceSessionProvider);

    ref.listen<PracticeSessionState>(practiceSessionProvider, (prev, next) {
      if (prev == null) return;

      final currentIdx = next.currentIndex;
      final prevFeedback = currentIdx < prev.feedback.length
          ? prev.feedback[currentIdx]
          : null;
      final nextFeedback = currentIdx < next.feedback.length
          ? next.feedback[currentIdx]
          : null;

      // Feedback just arrived
      if (prevFeedback == null && nextFeedback != null) {
        _onFeedbackReceived(nextFeedback);
      }

      // Session completed
      if (!prev.isCompleted && next.isCompleted && next.questions.isNotEmpty) {
        context.pushNamed(
          RouteNames.practiceResult, // Assuming this is added to RouteNames
          pathParameters: {'id': next.sessionId!},
        );
      }
    });

    // Handle timer start on first load
    if (state.questions.isNotEmpty &&
        state.currentIndex == 0 &&
        !_answered &&
        !_timerController.isAnimating &&
        !_timerController.isCompleted) {
      _startTimer();
    }

    if (state.isLoading && state.questions.isEmpty) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Gap(16),
              Text('Starting practice...', style: AppTextStyles.body1),
            ],
          ),
        ),
      );
    }

    if (state.error != null && state.questions.isEmpty) {
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
              const Text('😕', style: TextStyle(fontSize: 64)),
              const Gap(16),
              Text(
                state.error!,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              AnimatedButton(
                text: 'Try Again',
                onPressed: () {
                  ref
                      .read(practiceSessionProvider.notifier)
                      .startSession(
                        widget.topic,
                        questionCount: widget.questionCount,
                      );
                },
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    if (state.questions.isEmpty) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        child: const Center(
          child: Text('No questions available.', style: AppTextStyles.body1),
        ),
      );
    }

    final question = state.currentQuestion!;
    final options = question.options;

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.topic.toUpperCase(), style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress and Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Problem ${state.currentIndex + 1} of ${state.questions.length}',
                              style: AppTextStyles.body2,
                            ),
                            const Gap(4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value:
                                    (state.currentIndex + 1) /
                                    state.questions.length,
                                minHeight: 8,
                                backgroundColor: AppColors.disabled.withValues(
                                  alpha: 0.3,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Score', style: AppTextStyles.body2),
                          Text(
                            '${state.score}',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(16),

                  // Timer
                  Center(child: _buildTimer()),
                  const Gap(16),

                  // Combo Counter
                  Center(
                    child: _buildComboCounter(
                      state.comboCount,
                      state.comboMultiplier,
                    ),
                  ),
                  const Gap(24),

                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'What is the answer?',
                          style: AppTextStyles.body2,
                        ),
                        const Gap(20),
                        Text(
                              '${question.questionText} = ?',
                              style: AppTextStyles.mathExpression,
                              textAlign: TextAlign.center,
                            )
                            .animate(key: ValueKey(question.id))
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // Answers
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(options.length, (index) {
                      final option = options[index];
                      // Try parse option to double, default to 0 if fails (though it should be number)
                      final val = double.tryParse(option) ?? 0.0;

                      return _AnswerButton(
                        answer: option,
                        isSelected: _selectedAnswer == index,
                        isCorrect: _isCorrect && index == _selectedAnswer,
                        isWrong:
                            _answered &&
                            index == _selectedAnswer &&
                            !_isCorrect,
                        onTap: _answered
                            ? null
                            : () => _selectAnswer(index, val),
                        shakeController: _shakeController,
                        delay: index * 100,
                      );
                    }),
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.success,
                AppColors.warning,
                Colors.purple,
              ],
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, child) {
        // Calculate remaining seconds based on controller value (0.0 to 1.0)
        final remaining = (30 * (1 - _timerController.value)).ceil();
        final color = remaining > 10
            ? AppColors.success
            : remaining > 5
            ? AppColors.warning
            : AppColors.error;
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1 - _timerController.value,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(color),
                backgroundColor: AppColors.disabled.withValues(alpha: 0.3),
              ),
              Text(
                '$remaining',
                style: AppTextStyles.heading3.copyWith(color: color),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComboCounter(int comboCount, double multiplier) {
    if (comboCount < 3) {
      return const SizedBox(height: 48);
    }

    return AnimatedBuilder(
          animation: _comboController,
          builder: (context, child) {
            final scale = 1.0 + (_comboController.value * 0.3);
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.warning],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const Gap(8),
                    Text(
                      '${comboCount}x Combo!',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      '${multiplier.toStringAsFixed(1)}x',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        .animate(target: 1)
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _AnswerButton extends StatefulWidget {
  const _AnswerButton({
    required this.answer,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
    required this.shakeController,
    required this.delay,
  });

  final String answer;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  final AnimationController shakeController;
  final int delay;

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _localShakeController;

  @override
  void initState() {
    super.initState();
    // We can use the parent's controller or a local one.
    // The instructions say "Has its own _shakeController for per-button shake".
    // But passed in props? "add shake animation using the parent's _shakeController"
    // Wait, prompt says: "Has its own _shakeController for per-button shake" AND "add shake animation using the parent's _shakeController"
    // Actually, checking prompt: "_AnswerButton (inner class): Follow the exact pattern... but add shake animation using the parent's _shakeController"
    // AND then immediately: "- StatefulWidget... - Has its own _shakeController for per-button shake"
    // Use local controller for cleaner encapsulation if allowed, but I'll follow "Has its own".
    _localShakeController = AnimationController(vsync: this, duration: 400.ms);
  }

  @override
  void didUpdateWidget(_AnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWrong && !oldWidget.isWrong) {
      _localShakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _localShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = AppColors.primary;
    Color borderColor = AppColors.primary.withValues(alpha: 0.3);
    Color backgroundColor = AppColors.primary.withValues(alpha: 0.1);

    if (widget.isCorrect) {
      buttonColor = AppColors.success;
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.15);
    } else if (widget.isWrong) {
      buttonColor = AppColors.error;
      borderColor = AppColors.error;
      backgroundColor = AppColors.error.withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _localShakeController,
        builder: (context, child) {
          final shakeOffset =
              10.0 *
              ((0.5 - (0.5 - _localShakeController.value).abs()) * 2) *
              sin(_localShakeController.value * pi * 4);

          return Transform.translate(
            offset: Offset(widget.isWrong ? shakeOffset : 0, 0),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: widget.isSelected ? buttonColor : borderColor,
              width: widget.isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                      widget.answer,
                      style: AppTextStyles.heading3.copyWith(
                        color: buttonColor,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: widget.delay),
                    )
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                      delay: Duration(milliseconds: widget.delay),
                      curve: Curves.elasticOut,
                    ),
                if (widget.isCorrect)
                  const Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 48,
                          color: AppColors.success,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1.2, 1.2),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                if (widget.isWrong)
                  const Text(
                        '✗',
                        style: TextStyle(fontSize: 48, color: AppColors.error),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1.2, 1.2),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
