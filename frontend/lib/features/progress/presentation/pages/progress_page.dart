import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../domain/entities/topic_progress_entity.dart';
import '../notifiers/progress_notifier.dart';
import '../providers/progress_providers.dart';
import '../widgets/accuracy_line_chart.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/speed_line_chart.dart';
import '../widgets/weekly_comparison_bar_chart.dart';

/// Progress page showing statistics, charts, and achievements.
///
/// Integrates fl_chart for accuracy trends, speed trends, weekly comparison,
/// and skill breakdown radar chart alongside existing streak/stats/topic cards.
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage();

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  @override
  void initState() {
    super.initState();
    // Trigger loading on first build
    Future.microtask(
      () => ref.read(progressNotifierProvider.notifier).loadProgress(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressNotifierProvider);

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Your Progress 📈', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      child: _buildBody(progressState),
    );
  }

  Widget _buildBody(ProgressState progressState) {
    if (progressState.isLoading && !progressState.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (progressState.error != null && !progressState.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('😕', style: const TextStyle(fontSize: 64)),
              const Gap(16),
              Text(
                progressState.error!,
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(progressNotifierProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final summary = progressState.summary;
    final topicProgress = progressState.topicProgress;

    return RefreshIndicator(
      onRefresh: () => ref.read(progressNotifierProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Streak Display ──────────────────────────────
              _StreakCard(currentStreak: summary?.currentStreak ?? 0),
              const Gap(24),

              // ─── Stats Overview ──────────────────────────────
              Text('Overall Stats', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 100.ms),
              const Gap(12),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatTile(
                    icon: '✅',
                    label: 'Completed',
                    value: '${summary?.totalExercises ?? 0}',
                    color: AppColors.success,
                    delay: 200,
                  ),
                  _StatTile(
                    icon: '⭐',
                    label: 'Accuracy',
                    value: '${summary?.accuracyRate.toStringAsFixed(0) ?? 0}%',
                    color: AppColors.warning,
                    delay: 300,
                  ),
                  _StatTile(
                    icon: '🏆',
                    label: 'Best Streak',
                    value: '${summary?.longestStreak ?? 0}',
                    color: AppColors.grade1,
                    delay: 400,
                  ),
                ],
              ),
              const Gap(24),

              // ─── Accuracy Trend Chart ────────────────────────
              if (progressState.isLoadingCharts && !progressState.hasChartData)
                _ChartLoadingPlaceholder(delay: 200)
              else if (progressState.accuracyHistory.isNotEmpty)
                AccuracyLineChart(dataPoints: progressState.accuracyHistory)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      delay: 200.ms,
                    ),
              if (progressState.accuracyHistory.isNotEmpty) const Gap(24),

              // ─── Weekly Comparison Chart ─────────────────────
              if (progressState.weeklyComparison != null)
                WeeklyComparisonBarChart(data: progressState.weeklyComparison!)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      delay: 300.ms,
                    ),
              if (progressState.weeklyComparison != null) const Gap(24),

              // ─── Speed Trend Chart ───────────────────────────
              if (progressState.speedHistory.isNotEmpty)
                SpeedLineChart(dataPoints: progressState.speedHistory)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      delay: 400.ms,
                    ),
              if (progressState.speedHistory.isNotEmpty) const Gap(24),

              // ─── Skill Radar Chart ───────────────────────────
              if (topicProgress.isNotEmpty)
                SkillRadarChart(topicProgress: topicProgress)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      delay: 500.ms,
                    ),
              if (topicProgress.isNotEmpty) const Gap(24),

              // ─── Topic Mastery Cards ─────────────────────────
              Text('Topic Mastery', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 600.ms),
              const Gap(12),
              ..._buildTopicMasteryCards(topicProgress),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds topic mastery cards from real data, falling back to defaults
  /// if no data is available.
  List<Widget> _buildTopicMasteryCards(
    List<TopicProgressEntity> topicProgress,
  ) {
    const topicConfig = [
      {'topic': 'addition', 'label': 'Addition', 'emoji': '➕'},
      {'topic': 'subtraction', 'label': 'Subtraction', 'emoji': '➖'},
      {'topic': 'multiplication', 'label': 'Multiplication', 'emoji': '✖️'},
      {'topic': 'division', 'label': 'Division', 'emoji': '➗'},
    ];

    const topicColors = [
      AppColors.grade1,
      AppColors.grade2,
      AppColors.grade3,
      AppColors.grade4,
    ];

    final widgets = <Widget>[];

    for (var i = 0; i < topicConfig.length; i++) {
      final config = topicConfig[i];
      final topicData = topicProgress
          .where((t) => t.topic == config['topic'])
          .firstOrNull;

      final percentage = topicData?.masteryScore.round() ?? 0;

      if (i > 0) {
        widgets.add(const Gap(12));
      }

      widgets.add(
        _MasteryCard(
          topic: config['label']!,
          emoji: config['emoji']!,
          percentage: percentage,
          color: topicColors[i],
          delay: 700 + (i * 100),
        ),
      );
    }

    return widgets;
  }
}

// ─── Streak Card ───────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Current Streak',
                style: AppTextStyles.body2.copyWith(color: Colors.white70),
              ),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔥', style: const TextStyle(fontSize: 48)),
                  const Gap(12),
                  Text(
                    '$currentStreak Days',
                    style: AppTextStyles.scoreDisplay.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Text(
                'Keep it up! Complete a problem to extend your streak.',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0, duration: 600.ms);
  }
}

// ─── Chart Loading Placeholder ─────────────────────────────────────────

class _ChartLoadingPlaceholder extends StatelessWidget {
  const _ChartLoadingPlaceholder({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Gap(12),
              Text('Loading charts...', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 600.ms,
      delay: Duration(milliseconds: delay),
    );
  }
}

// ─── Stat Tile ─────────────────────────────────────────────────────────

/// Stat tile showing icon, label, and value.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const Gap(6),
              Text(
                label,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const Gap(4),
              Text(
                value,
                style: AppTextStyles.heading4.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: delay),
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          delay: Duration(milliseconds: delay),
          curve: Curves.easeOutBack,
        );
  }
}

// ─── Topic Mastery Card ────────────────────────────────────────────────

/// Topic mastery card showing progress.
class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.topic,
    required this.emoji,
    required this.percentage,
    required this.color,
    required this.delay,
  });

  final String topic;
  final String emoji;
  final int percentage;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topic, style: AppTextStyles.heading4),
                        const Gap(4),
                        Text('Mastery Level', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: AppTextStyles.heading4.copyWith(color: color),
                  ),
                ],
              ),
              const Gap(12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: delay),
        )
        .slideX(
          begin: -0.2,
          end: 0,
          duration: 600.ms,
          delay: Duration(milliseconds: delay),
        );
  }
}
