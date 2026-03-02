import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../domain/entities/match_entity.dart';
import '../notifiers/match_notifier.dart';
import '../providers/competition_providers.dart';

/// The main competition match page.
///
/// Displays the live match: opponent info, score bars, countdown,
/// questions, and answer options with animations.
class CompetitionMatchPage extends ConsumerStatefulWidget {
  const CompetitionMatchPage({super.key});

  @override
  ConsumerState<CompetitionMatchPage> createState() =>
      _CompetitionMatchPageState();
}

class _CompetitionMatchPageState extends ConsumerState<CompetitionMatchPage>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _shakeController = AnimationController(vsync: this, duration: 400.ms);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchNotifierProvider);

    ref.listen<MatchState>(matchNotifierProvider, (prev, next) {
      // Navigate to result page when match completes.
      if (prev?.status != MatchStatus.completed &&
          next.status == MatchStatus.completed) {
        context.pushReplacementNamed(RouteNames.competitionResult);
      }

      // Trigger animations on answer result.
      if (prev?.lastAnswerCorrect == null && next.lastAnswerCorrect != null) {
        if (next.lastAnswerCorrect!) {
          _confettiController.play();
        } else {
          _shakeController.forward(from: 0);
        }
      }
    });

    // Countdown overlay.
    if (state.status == MatchStatus.countdown) {
      return GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.opponent != null) ...[
                const Text(
                  'VS',
                  style: AppTextStyles.heading2,
                ).animate().fadeIn(duration: 400.ms),
                const Gap(16),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.secondaryLight,
                  child: Text(
                    state.opponent!.displayName.isNotEmpty
                        ? state.opponent!.displayName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
                const Gap(8),
                Text(
                  state.opponent!.displayName,
                  style: AppTextStyles.heading3,
                ),
                const Gap(32),
              ],
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(
                  AssetPaths.countdownAnimation,
                  fit: BoxFit.contain,
                ),
              ),
              const Gap(16),
              Text(
                    '${state.countdownSeconds}',
                    style: AppTextStyles.scoreDisplay.copyWith(fontSize: 72),
                  )
                  .animate(key: ValueKey(state.countdownSeconds))
                  .scale(
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 300.ms),
              const Gap(8),
              const Text('Get Ready!', style: AppTextStyles.heading3),
            ],
          ),
        ),
      );
    }

    // Disconnected overlay.
    if (state.status == MatchStatus.disconnected) {
      return GradientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('😔', style: TextStyle(fontSize: 64)),
                const Gap(16),
                const Text(
                  'Opponent Disconnected',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const Gap(8),
                const Text(
                  'Your opponent left the match. Don\'t worry, you\'re still a math star!',
                  style: AppTextStyles.body1,
                  textAlign: TextAlign.center,
                ),
                const Gap(32),
                _buildActionButton('Back to Lobby', AppColors.primary, () {
                  ref.read(matchNotifierProvider.notifier).reset();
                  context.pushReplacementNamed(RouteNames.competitionLobby);
                }),
              ],
            ),
          ),
        ),
      );
    }

    // Main match UI.
    final question = state.currentQuestion;

    return GradientBackground(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Score bar header.
                _buildScoreHeader(state),
                const Gap(8),

                // Timer.
                _buildTimer(state.timeRemainingSeconds),
                const Gap(8),

                // Encouragement message.
                if (state.encouragementMessage != null)
                  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          state.encouragementMessage!,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                      .animate(key: ValueKey(state.encouragementMessage))
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0, duration: 400.ms),
                const Gap(16),

                // Question progress.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${state.questionIndex + 1} of ${state.totalQuestions}',
                        style: AppTextStyles.body2,
                      ),
                      if (state.playerStreak >= 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.secondary, AppColors.warning],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🔥 ${state.playerStreak}x Streak',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                    ],
                  ),
                ),
                const Gap(8),

                // Progress bar.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.totalQuestions > 0
                          ? (state.questionIndex + 1) / state.totalQuestions
                          : 0,
                      minHeight: 6,
                      backgroundColor: AppColors.disabled.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.success,
                      ),
                    ),
                  ),
                ),
                const Gap(24),

                // Question card.
                if (question != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
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

                          // Answer options.
                          GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: List.generate(question.options.length, (
                              index,
                            ) {
                              final option = question.options[index];
                              final val = double.tryParse(option) ?? 0.0;
                              final isSelected = state.selectedAnswer == val;
                              final isCorrectAnswer =
                                  state.lastAnswerCorrect == true && isSelected;
                              final isWrongAnswer =
                                  state.lastAnswerCorrect == false &&
                                  isSelected;

                              return _MatchAnswerButton(
                                answer: option,
                                isSelected: isSelected,
                                isCorrect: isCorrectAnswer,
                                isWrong: isWrongAnswer,
                                isDisabled: state.selectedAnswer != null,
                                onTap: state.selectedAnswer != null
                                    ? null
                                    : () => ref
                                          .read(matchNotifierProvider.notifier)
                                          .submitAnswer(val),
                                shakeController: _shakeController,
                                delay: index * 80,
                              );
                            }),
                          ),
                          const Gap(32),
                        ],
                      ),
                    ),
                  ),

                if (question == null && state.status == MatchStatus.inProgress)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // Confetti overlay.
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
              numberOfParticles: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(MatchState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Player.
          Expanded(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text('🧒', style: TextStyle(fontSize: 20)),
                ),
                const Gap(4),
                const Text('You', style: AppTextStyles.caption),
                Text(
                  '${state.playerScore}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // VS divider with score bars.
          Column(
            children: [
              const Text(
                'VS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const Gap(4),
              SizedBox(
                width: 100,
                child: _buildScoreBars(state.playerScore, state.opponentScore),
              ),
            ],
          ),

          // Opponent.
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.secondaryLight,
                  child: Text(
                    state.opponent?.displayName.isNotEmpty == true
                        ? state.opponent!.displayName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(4),
                Text(
                  state.opponent?.displayName ?? 'Opponent',
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${state.opponentScore}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBars(int playerScore, int opponentScore) {
    final total = playerScore + opponentScore;
    final playerRatio = total > 0 ? playerScore / total : 0.5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Expanded(
              flex: (playerRatio * 100).round().clamp(5, 95),
              child: Container(color: AppColors.primary),
            ),
            Expanded(
              flex: ((1 - playerRatio) * 100).round().clamp(5, 95),
              child: Container(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(int seconds) {
    final color = seconds > 15
        ? AppColors.success
        : seconds > 5
        ? AppColors.warning
        : AppColors.error;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: seconds / 30,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(color),
            backgroundColor: AppColors.disabled.withValues(alpha: 0.3),
          ),
          Text(
            '$seconds',
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(text, style: AppTextStyles.button),
      ),
    );
  }
}

class _MatchAnswerButton extends StatefulWidget {
  const _MatchAnswerButton({
    required this.answer,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.isDisabled,
    required this.onTap,
    required this.shakeController,
    required this.delay,
  });

  final String answer;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;
  final VoidCallback? onTap;
  final AnimationController shakeController;
  final int delay;

  @override
  State<_MatchAnswerButton> createState() => _MatchAnswerButtonState();
}

class _MatchAnswerButtonState extends State<_MatchAnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _localShakeController;

  @override
  void initState() {
    super.initState();
    _localShakeController = AnimationController(vsync: this, duration: 400.ms);
  }

  @override
  void didUpdateWidget(_MatchAnswerButton oldWidget) {
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
      onTap: widget.isDisabled ? null : widget.onTap,
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
