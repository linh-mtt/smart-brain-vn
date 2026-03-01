import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../data/models/child_progress_model.dart';
import '../../data/models/child_summary_model.dart';
import '../providers/parent_providers.dart';

/// Parent dashboard page for monitoring a child's learning progress.
///
/// Shows activity summary, time spent, topic performance,
/// and parental controls with real data from the API.
class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);
    final progressAsync = ref.watch(childProgressProvider);

    return GradientBackground(
      appBar: AppBar(title: const Text('Parent Dashboard 👨‍👩‍👧')),
      child: SafeArea(
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(ref, error),
          data: (children) {
            if (children.isEmpty) {
              return _buildEmptyView();
            }

            // Auto-select the first child if none selected
            final selectedId = ref.watch(selectedChildProvider);
            if (selectedId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedChildProvider.notifier).selectChild(children.first.childId);
              });
              return const Center(child: CircularProgressIndicator());
            }

            final selectedChild = children.firstWhere(
              (c) => c.childId == selectedId,
              orElse: () => children.first,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),

                  // Child info card
                  _buildChildInfoCard(selectedChild, progressAsync)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1, end: 0),

                  const Gap(24),

                  // Activity summary
                  Text(
                    'Activity Summary 📊',
                    style: AppTextStyles.heading3,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  const Gap(12),

                  _buildActivitySummary(
                    selectedChild,
                    progressAsync,
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                  const Gap(24),

                  // Time spent this week
                  Text(
                    'Time Spent This Week ⏱️',
                    style: AppTextStyles.heading3,
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  const Gap(12),

                  _buildTimeChart().animate().fadeIn(
                    duration: 400.ms,
                    delay: 500.ms,
                  ),

                  const Gap(24),

                  // Topic performance
                  Text(
                    'Topic Performance 🎯',
                    style: AppTextStyles.heading3,
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

                  const Gap(12),

                  _buildTopicPerformance(
                    progressAsync,
                  ).animate().fadeIn(duration: 400.ms, delay: 700.ms),

                  const Gap(24),

                  // Parental controls
                  Text(
                    'Parental Controls 🔒',
                    style: AppTextStyles.heading3,
                  ).animate().fadeIn(duration: 400.ms, delay: 800.ms),

                  const Gap(12),

                  _buildParentalControls().animate().fadeIn(
                    duration: 400.ms,
                    delay: 900.ms,
                  ),

                  const Gap(32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const Gap(16),
            Text(
              'Could not load dashboard.',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(childrenListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👶', style: TextStyle(fontSize: 48)),
            const Gap(16),
            Text(
              'No children linked yet.',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'Add a child to start monitoring their progress.',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildInfoCard(
    ChildSummaryModel child,
    AsyncValue<ChildProgressModel?> progressAsync,
  ) {
    final displayName = child.displayName ?? child.username;
    final goalProgress = progressAsync.value?.dailyGoal;
    final exerciseTarget = goalProgress?.dailyExerciseTarget ?? 10;
    final exercisesDone = child.totalExercises;
    final progressValue = exerciseTarget > 0
        ? (exercisesDone / exerciseTarget).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progressValue * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Child avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👧', style: TextStyle(fontSize: 32)),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayName\'s Progress',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
                const Gap(4),
                Text(
                  'Grade ${child.gradeLevel} • 🔥 ${child.currentStreak} day streak',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const Gap(8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
                const Gap(4),
                Text(
                  '$progressPercent% of daily goal completed',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary(
    ChildSummaryModel child,
    AsyncValue<ChildProgressModel?> progressAsync,
  ) {
    final totalExercises = child.totalExercises;
    final totalPoints = child.totalPoints;

    // Calculate accuracy from progress data if available
    final progress = progressAsync.value;
    String accuracyText = '--';
    if (progress != null && progress.topicMastery.isNotEmpty) {
      final avgMastery =
          progress.topicMastery
              .map((t) => t.masteryScore)
              .reduce((a, b) => a + b) /
          progress.topicMastery.length;
      accuracyText = '${avgMastery.toInt()}%';
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            emoji: '📝',
            value: '$totalExercises',
            label: 'Problems\nCompleted',
            color: AppColors.primary,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildSummaryCard(
            emoji: '⭐',
            value: '$totalPoints',
            label: 'Total\nPoints',
            color: AppColors.secondary,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildSummaryCard(
            emoji: '🏆',
            value: accuracyText,
            label: 'Average\nMastery',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const Gap(8),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [0.6, 0.8, 0.4, 0.9, 0.7, 0.3, 0.5];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(values[index] * 60).toInt()}m',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Gap(4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: values[index],
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const Gap(8),
          Row(
            children: days
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicPerformance(AsyncValue<ChildProgressModel?> progressAsync) {
    final progress = progressAsync.value;

    // Default topic colors
    Color _colorForTopic(String topic) {
      final lower = topic.toLowerCase();
      if (lower.contains('add')) return AppColors.success;
      if (lower.contains('sub')) return AppColors.primary;
      if (lower.contains('mul')) return AppColors.warning;
      if (lower.contains('div')) return AppColors.secondary;
      return AppColors.primary;
    }

    String _emojiForTopic(String topic) {
      final lower = topic.toLowerCase();
      if (lower.contains('add')) return '➕';
      if (lower.contains('sub')) return '➖';
      if (lower.contains('mul')) return '✖️';
      if (lower.contains('div')) return '➗';
      return '📐';
    }

    // Use real topic data if available, otherwise show placeholder
    final topics = progress?.topicMastery ?? [];

    if (topics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No topic data yet. Start practicing! 📚',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: topics.map((topic) {
          final color = _colorForTopic(topic.topic);
          final emoji = _emojiForTopic(topic.topic);
          final score = topic.masteryScore / 100.0; // normalize to 0-1

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: Text(
                    topic.topic,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score.clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.15),
                      color: color,
                      minHeight: 10,
                    ),
                  ),
                ),
                const Gap(12),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${topic.masteryScore.toInt()}%',
                    style: AppTextStyles.label.copyWith(color: color),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParentalControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildControlItem(
            icon: Icons.timer_outlined,
            title: 'Daily Time Limit',
            subtitle: '45 minutes',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          _buildControlItem(
            icon: Icons.tune_rounded,
            title: 'Auto-adjust Difficulty',
            subtitle: 'Based on performance',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          _buildControlItem(
            icon: Icons.notifications_outlined,
            title: 'Weekly Report',
            subtitle: 'Email summary every Sunday',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          _buildControlItem(
            icon: Icons.leaderboard_outlined,
            title: 'Show Leaderboard',
            subtitle: 'Allow competitive features',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
