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

/// Progress page showing statistics and achievements.
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
              // Streak Display
              Container(
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
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🔥', style: const TextStyle(fontSize: 48)),
                            const Gap(12),
                            Text(
                              '${summary?.currentStreak ?? 0} Days',
                              style: AppTextStyles.scoreDisplay.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        Text(
                          'Keep it up! Complete a problem to extend your streak.',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.2, end: 0, duration: 600.ms),
              const Gap(24),

              // Stats Overview
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

              // Weekly Activity Chart (kept as mock — no weekly endpoint)
              Text('Weekly Activity', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms),
              const Gap(12),
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider, width: 1),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _ActivityBar(
                                day: 'Mon',
                                height: 0.4,
                                color: AppColors.grade1,
                                delay: 300,
                              ),
                              _ActivityBar(
                                day: 'Tue',
                                height: 0.6,
                                color: AppColors.grade2,
                                delay: 400,
                              ),
                              _ActivityBar(
                                day: 'Wed',
                                height: 0.8,
                                color: AppColors.grade3,
                                delay: 500,
                              ),
                              _ActivityBar(
                                day: 'Thu',
                                height: 0.5,
                                color: AppColors.grade4,
                                delay: 600,
                              ),
                              _ActivityBar(
                                day: 'Fri',
                                height: 0.9,
                                color: AppColors.grade5,
                                delay: 700,
                              ),
                              _ActivityBar(
                                day: 'Sat',
                                height: 1.0,
                                color: AppColors.grade6,
                                delay: 800,
                              ),
                              _ActivityBar(
                                day: 'Sun',
                                height: 0.7,
                                color: AppColors.primary,
                                delay: 900,
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'Problems solved this week',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 300.ms),
              const Gap(24),

              // Topic Mastery
              Text('Topic Mastery', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 400.ms),
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
          delay: 500 + (i * 100),
        ),
      );
    }

    return widgets;
  }
}

/// Stat tile showing icon, label, and value
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

/// Activity bar for weekly chart
class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.day,
    required this.height,
    required this.color,
    required this.delay,
  });

  final String day;
  final double height;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
              width: 24,
              height: 100 * height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(
              duration: 600.ms,
              delay: Duration(milliseconds: delay),
            )
            .scaleY(
              begin: 0,
              end: 1,
              duration: 600.ms,
              delay: Duration(milliseconds: delay),
              curve: Curves.easeOutBack,
            ),
        const Gap(8),
        Text(day, style: AppTextStyles.caption),
      ],
    );
  }
}

/// Topic mastery card showing progress
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
