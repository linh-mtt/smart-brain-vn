import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../providers/competition_providers.dart';

/// Displays the result of a completed competition match.
///
/// Shows victory/defeat animation, score comparison, stats breakdown,
/// and friendly encouragement messages.
class CompetitionResultPage extends ConsumerStatefulWidget {
  const CompetitionResultPage({super.key});

  @override
  ConsumerState<CompetitionResultPage> createState() =>
      _CompetitionResultPageState();
}

class _CompetitionResultPageState extends ConsumerState<CompetitionResultPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Play confetti on victory.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = ref.read(matchNotifierProvider).matchResult;
      if (result != null && result.isVictory) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchNotifierProvider);
    final result = state.matchResult;

    if (result == null) {
      return const GradientBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isVictory = result.isVictory;
    final accentColor = isVictory ? AppColors.warning : AppColors.primary;

    return GradientBackground(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Gap(16),

                  // Victory / Defeat animation.
                  Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Lottie.asset(
                            isVictory
                                ? AssetPaths.victoryAnimation
                                : AssetPaths.defeatAnimation,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),

                  const Gap(16),

                  // Title.
                  Text(
                        isVictory ? 'You Won! 🏆' : 'Good Try! 💪',
                        style: AppTextStyles.heading1.copyWith(
                          color: accentColor,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, duration: 600.ms),

                  const Gap(8),

                  // Encouragement.
                  Text(
                    isVictory
                        ? 'Amazing math skills! You\'re a champion! 🌟'
                        : 'Every match makes you stronger! Keep practicing! 🌈',
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

                  const Gap(32),

                  // Score comparison card.
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Player score.
                        Expanded(
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  '🧒',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              const Gap(8),
                              const Text('You', style: AppTextStyles.body2),
                              Text(
                                '${result.playerScore}',
                                style: AppTextStyles.scoreDisplay.copyWith(
                                  fontSize: 40,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // VS.
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                'VS',
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Opponent score.
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.secondaryLight,
                                child: Text(
                                  result.opponentName.isNotEmpty
                                      ? result.opponentName[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.body1.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Gap(8),
                              Text(
                                result.opponentName.isNotEmpty
                                    ? result.opponentName
                                    : 'Opponent',
                                style: AppTextStyles.body2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${result.opponentScore}',
                                style: AppTextStyles.scoreDisplay.copyWith(
                                  fontSize: 40,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 500.ms),

                  const Gap(24),

                  // Stats grid.
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
                        '${result.accuracy.toStringAsFixed(1)}%',
                        Icons.check_circle_outline,
                        AppColors.success,
                        600,
                      ),
                      _buildStatCard(
                        'Correct',
                        '${result.correctAnswers}/${result.questionsAnswered}',
                        Icons.task_alt,
                        AppColors.primary,
                        700,
                      ),
                      _buildStatCard(
                        'Points',
                        '+${result.pointsEarned}',
                        Icons.star_rounded,
                        AppColors.warning,
                        800,
                      ),
                      _buildStatCard(
                        'ELO Change',
                        '${result.eloChange >= 0 ? '+' : ''}${result.eloChange}',
                        Icons.trending_up_rounded,
                        result.eloChange >= 0
                            ? AppColors.success
                            : AppColors.error,
                        900,
                      ),
                    ],
                  ),

                  const Gap(24),

                  // Time.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(8),
                        Text(
                          'Total time: ${_formatTime(result.totalTimeMs)}',
                          style: AppTextStyles.body1,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms),

                  const Gap(32),

                  // Action buttons.
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedButton(
                          text: 'Home',
                          onPressed: () {
                            ref.read(matchNotifierProvider.notifier).reset();
                            context.go(RouteNames.homePath);
                          },
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: AnimatedButton(
                          text: 'Play Again',
                          onPressed: () {
                            ref.read(matchNotifierProvider.notifier).reset();
                            context.pushReplacementNamed(
                              RouteNames.competitionLobby,
                            );
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
              numberOfParticles: 40,
            ),
          ),
        ],
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

  String _formatTime(int totalTimeMs) {
    final seconds = totalTimeMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) return '${minutes}m ${remainingSeconds}s';
    return '${remainingSeconds}s';
  }
}
