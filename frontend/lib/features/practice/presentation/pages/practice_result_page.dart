import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/router/route_names.dart';
import '../providers/practice_providers.dart';

class PracticeResultPage extends ConsumerStatefulWidget {
  const PracticeResultPage({required this.sessionId, super.key});
  final String sessionId;

  @override
  ConsumerState<PracticeResultPage> createState() => _PracticeResultPageState();
}

class _PracticeResultPageState extends ConsumerState<PracticeResultPage> {
  @override
  Widget build(BuildContext context) {
    // The result page uses the practiceSessionProvider state that is still alive
    final state = ref.watch(practiceSessionProvider);

    // If session ID doesn't match or state is empty (e.g. page refresh), handle gracefully
    // But assuming flow from practice page, state should be valid.
    if (state.questions.isEmpty) {
      return const GradientBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine accuracy
    final accuracy = state.accuracy;
    final score = state.score;
    final maxCombo = state.maxCombo;
    final correctCount = state.correctCount;
    final totalQuestions = state.questions.length;
    final totalTimeMs = state.totalTimeMs;
    final difficultyStart = state.difficultyStart;
    final currentDifficulty = state.currentDifficulty;

    return GradientBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                    'Practice Complete! 🎉',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms),

              const Gap(32),

              // Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Text('Total Score', style: AppTextStyles.body1),
                    const Gap(8),
                    Text(
                      '$score',
                      style: AppTextStyles.scoreDisplay.copyWith(fontSize: 64),
                    ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                    const Gap(4),
                    const Text('points', style: AppTextStyles.body2),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              const Gap(24),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    'Accuracy',
                    '${accuracy.toStringAsFixed(1)}%',
                    Icons.check_circle_outline,
                    AppColors.success,
                    300,
                  ),
                  _buildStatCard(
                    'Max Combo',
                    '${maxCombo}x 🔥',
                    Icons.local_fire_department,
                    AppColors.warning,
                    400,
                  ),
                  _buildStatCard(
                    'Correct',
                    '$correctCount/$totalQuestions',
                    Icons.task_alt,
                    AppColors.primary,
                    500,
                  ),
                  _buildStatCard(
                    'Time',
                    _formatTime(totalTimeMs),
                    Icons.timer_outlined,
                    AppColors.secondary,
                    600,
                  ),
                ],
              ),

              const Gap(24),

              // Difficulty Progression
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDifficultyBadge(difficultyStart, 'Start'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    _buildDifficultyBadge(currentDifficulty, 'End'),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms),

              const Gap(32),

              // Question Breakdown Title
              const Text(
                'Question Breakdown',
                style: AppTextStyles.heading3,
              ).animate().fadeIn(delay: 800.ms),
              const Gap(16),

              // Question List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.questions.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final question = state.questions[index];
                  final feedback = index < state.feedback.length
                      ? state.feedback[index]
                      : null;
                  final isCorrect = feedback?.isCorrect ?? false;

                  return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: isCorrect
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 20,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${question.questionText} = ?',
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!isCorrect) ...[
                                    const Gap(4),
                                    Text(
                                      'Correct: ${question.correctAnswer}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${feedback?.pointsEarned ?? 0} pts',
                                  style: AppTextStyles.body2.copyWith(
                                    color: isCorrect
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if ((feedback?.comboCount ?? 0) > 1)
                                  Text(
                                    '${feedback?.comboCount}x Combo',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 900 + (index * 100)),
                      )
                      .slideX(begin: 0.1, end: 0);
                },
              ),

              const Gap(32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: 'Home',
                      onPressed: () => context.go(RouteNames.homePath),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: AnimatedButton(
                      text: 'Practice Again',
                      onPressed: () {
                        ref.read(practiceSessionProvider.notifier).reset();
                        context
                            .pop(); // Go back to practice page which should re-init or we push new one?
                        // Ideally we should replace or reset.
                        // If we pop, we go back to the *completed* practice page.
                        // We need to reset the state, then POP back to practice page (which will re-init because of autodispose? No, it's a notifier)
                        // Wait, if we pop, we are back at PracticePage. PracticePage checks "isCompleted" in build? No.
                        // PracticePage listens to state.
                        // Best is to pop and let PracticePage re-init.
                        // But PracticePage init logic is in initState with `startSession`.
                        // If we pop, the PracticePage instance might still be there if we pushed result on top.
                        // If we use GoRouter `push`, yes.
                        // If we `pop`, we go back to the previous route.
                        // Actually, we should probably `pushReplacement` to a new PracticePage or just reset state and pop.
                        // If we reset state, `isCompleted` becomes false.
                        // PracticePage `build` will see `currentIndex=0` etc.
                        // But `PracticePage` `initState` calls `startSession`.
                        // If we pop, we go back to the *existing* PracticePage instance.
                        // We should use `context.pushReplacementNamed` to start a FRESH practice page?
                        // Or `ref.read(...).startSession` again?

                        // Re-read requirements: "Reset the practice session... Pop back and start a new session"
                        // If we pop, we return to the *previous* page.
                        // If the previous page was `PracticePage`, it's still mounted.
                        // We should trigger a restart there.
                        // Let's just `startSession` again and pop.
                        // The `PracticePage` will rebuild with new state.

                        // BUT `PracticePage` logic:
                        // `ref.listen` handles completion.
                        // `initState` starts session.
                        // If we just change state, `PracticePage` will update.

                        // Let's do:
                        ref
                            .read(practiceSessionProvider.notifier)
                            .startSession(
                              state.topic, // Use same topic
                              questionCount:
                                  state.questions.length, // Use same count
                            );
                        context.pop();
                      },
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    int delay,
  ) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const Gap(8),
              Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
              const Gap(4),
              Text(label, style: AppTextStyles.body2),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 500.ms,
          delay: Duration(milliseconds: delay),
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 500.ms,
          delay: Duration(milliseconds: delay),
        );
  }

  Widget _buildDifficultyBadge(int level, String label) {
    final color = AppColors.gradeColor(level);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            'Level $level',
            style: AppTextStyles.body2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Gap(4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  String _formatTime(int totalTimeMs) {
    final seconds = totalTimeMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) return '${minutes}m ${remainingSeconds}s';
    return '${remainingSeconds}s';
  }
}
