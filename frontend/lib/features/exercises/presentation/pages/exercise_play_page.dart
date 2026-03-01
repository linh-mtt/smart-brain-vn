import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../notifiers/exercise_notifier.dart';
import '../providers/exercise_providers.dart';

/// Exercise play page with math problems and answer options.
class ExercisePlayPage extends ConsumerStatefulWidget {
  const ExercisePlayPage({
    required this.topic,
    required this.difficulty,
    super.key,
  });
  final String topic;
  final String difficulty;
  @override
  ConsumerState<ExercisePlayPage> createState() => _ExercisePlayPageState();
}

class _ExercisePlayPageState extends ConsumerState<ExercisePlayPage>
    with TickerProviderStateMixin {
  late AnimationController _feedbackController;
  late AnimationController _timerController;
  int _selectedAnswer = -1;
  bool _answered = false;
  bool _isCorrect = false;
  int _timeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: 600.ms);
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeRemaining),
    );

    // Extract topic and difficulty from the route param (e.g., "addition/easy")
    final topic = widget.topic;
    final difficulty = widget.difficulty;

    // Load exercises from the backend
    Future.microtask(() {
      ref
          .read(exerciseSessionProvider.notifier)
          .loadExercises(topic, difficulty);
    });
  }

  void _startTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    final sessionState = ref.read(exerciseSessionProvider);
    final exercise = sessionState.currentExercise;
    if (exercise == null) return;

    final options = exercise.options ?? [];
    if (index >= options.length) return;

    final selectedValue = double.tryParse(options[index]) ?? 0;

    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });

    // Submit answer to backend
    ref.read(exerciseSessionProvider.notifier).submitAnswer(selectedValue);
  }

  void _onFeedbackReceived(bool isCorrect) {
    setState(() {
      _isCorrect = isCorrect;
    });

    _feedbackController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _nextProblem();
      });
    });
  }

  void _nextProblem() {
    final notifier = ref.read(exerciseSessionProvider.notifier);
    notifier.nextProblem();

    final sessionState = ref.read(exerciseSessionProvider);
    if (!sessionState.isCompleted) {
      setState(() {
        _selectedAnswer = -1;
        _answered = false;
        _isCorrect = false;
        _timeRemaining = 30;
      });
      _feedbackController.reset();
      _startTimer();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final sessionState = ref.read(exerciseSessionProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Great Job! 🎉',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Final Score',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            Text(
              '${sessionState.score}',
              style: AppTextStyles.scoreDisplay,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'out of ${sessionState.totalPoints}',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              text: 'Back to Exercises',
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(exerciseSessionProvider);
    final topicLabel = widget.topic.toUpperCase();

    // Listen for feedback changes to trigger animations
    ref.listen<ExerciseSessionState>(exerciseSessionProvider, (prev, next) {
      if (prev == null) return;

      final currentIdx = next.currentIndex;
      final prevFeedback = currentIdx < prev.feedback.length
          ? prev.feedback[currentIdx]
          : null;
      final nextFeedback = currentIdx < next.feedback.length
          ? next.feedback[currentIdx]
          : null;

      // Feedback just arrived for the current exercise
      if (prevFeedback == null && nextFeedback != null) {
        _onFeedbackReceived(nextFeedback.isCorrect);
      }

      // Session just completed via state (e.g., loaded empty)
      if (!prev.isCompleted && next.isCompleted && next.exercises.isNotEmpty) {
        _showCompletionDialog();
      }
    });

    // Loading state
    if (sessionState.isLoading && sessionState.exercises.isEmpty) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(topicLabel, style: AppTextStyles.heading3),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Gap(16),
              Text('Generating problems...'),
            ],
          ),
        ),
      );
    }

    // Error state
    if (sessionState.error != null && sessionState.exercises.isEmpty) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(topicLabel, style: AppTextStyles.heading3),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 64)),
              const Gap(16),
              Text(
                sessionState.error!,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: () {
                  final topic = widget.topic;
                  final difficulty = widget.difficulty;
                  ref
                      .read(exerciseSessionProvider.notifier)
                      .loadExercises(topic, difficulty);
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (sessionState.exercises.isEmpty) {
      return GradientBackground(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(topicLabel, style: AppTextStyles.heading3),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: const Center(child: Text('No exercises available.')),
      );
    }

    final exercise = sessionState.currentExercise!;
    final options = exercise.options ?? [];
    final problemCount = sessionState.exercises.length;
    final currentIdx = sessionState.currentIndex;

    // Start timer on first exercise load
    if (currentIdx == 0 &&
        !_timerController.isAnimating &&
        !_timerController.isCompleted) {
      _startTimer();
    }

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(topicLabel, style: AppTextStyles.heading3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress and Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Problem ${currentIdx + 1} of $problemCount',
                        style: AppTextStyles.body2,
                      ),
                      const Gap(4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (currentIdx + 1) / problemCount,
                          minHeight: 8,
                          backgroundColor: AppColors.disabled.withValues(
                            alpha: 0.3,
                          ),
                          valueColor: AlwaysStoppedAnimation(AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Score', style: AppTextStyles.body2),
                      const Gap(4),
                      Text(
                        '${sessionState.score}',
                        style: AppTextStyles.scoreDisplay,
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(32),

              // Math Problem
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
                    Text('What is the answer?', style: AppTextStyles.body2),
                    const Gap(20),
                    Text(
                          '${exercise.questionText} = ?',
                          style: AppTextStyles.mathExpression,
                          textAlign: TextAlign.center,
                        )
                        .animate()
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
              const Gap(32),

              // Answer Options
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  options.length,
                  (index) => _AnswerButton(
                    answer: options[index],
                    isSelected: _selectedAnswer == index,
                    isCorrect: _isCorrect && index == _selectedAnswer,
                    isWrong:
                        _answered && index == _selectedAnswer && !_isCorrect,
                    onTap: _answered ? null : () => _selectAnswer(index),
                    delay: 100 * index,
                  ),
                ),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Answer button widget
class _AnswerButton extends StatefulWidget {
  const _AnswerButton({
    required this.answer,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
    required this.delay,
  });

  final String answer;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  final int delay;

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.isWrong) {
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
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
        animation: _shakeController,
        builder: (context, child) {
          final shake = (_shakeController.value - 0.5).abs() * 4;
          return Transform.translate(offset: Offset(shake, 0), child: child);
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
                  Text(
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
                  Text(
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
