import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Home page showing welcome, math topics, daily challenge, and stats.
class HomePage extends ConsumerWidget {
  const HomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return GradientBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome greeting
              Text(
                    'Hello, ${currentUser?.displayName ?? currentUser?.username ?? "Math Champion"}! 👋',
                    style: AppTextStyles.heading2,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms),
              const Gap(8),
              Text('Ready to learn today?', style: AppTextStyles.body2)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 100.ms),
              const Gap(24),

              // Math Topics Grid
              Text('Choose a Topic', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms),
              const Gap(12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _TopicCard(
                    emoji: '➕',
                    title: 'Addition',
                    color: AppColors.grade1,
                    delay: 300,
                    onTap: () => context.push(
                      RouteNames.exerciseTopicPath.replaceFirst(
                        ':topic',
                        'addition',
                      ),
                    ),
                  ),
                  _TopicCard(
                    emoji: '➖',
                    title: 'Subtraction',
                    color: AppColors.grade2,
                    delay: 400,
                    onTap: () => context.push(
                      RouteNames.exerciseTopicPath.replaceFirst(
                        ':topic',
                        'subtraction',
                      ),
                    ),
                  ),
                  _TopicCard(
                    emoji: '✖️',
                    title: 'Multiplication',
                    color: AppColors.grade3,
                    delay: 500,
                    onTap: () => context.push(
                      RouteNames.exerciseTopicPath.replaceFirst(
                        ':topic',
                        'multiplication',
                      ),
                    ),
                  ),
                  _TopicCard(
                    emoji: '➗',
                    title: 'Division',
                    color: AppColors.grade4,
                    delay: 600,
                    onTap: () => context.push(
                      RouteNames.exerciseTopicPath.replaceFirst(
                        ':topic',
                        'division',
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),

              // Daily Challenge
              Text('Daily Challenge 🎯', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 300.ms),
              const Gap(12),
              Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solve 5 multiplication problems!',
                          style: AppTextStyles.heading4.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          '3 of 5 completed',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Gap(12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: 0.6,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 400.ms),
              const Gap(24),

              // Stats Summary
              Text('Your Stats 📊', style: AppTextStyles.heading3)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 500.ms),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '🔥',
                      label: 'Streak',
                      value: '7 days',
                      color: AppColors.grade1,
                      delay: 600,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _StatCard(
                      icon: '✅',
                      label: 'Solved',
                      value: '42',
                      color: AppColors.grade4,
                      delay: 700,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _StatCard(
                      icon: '⭐',
                      label: 'Accuracy',
                      value: '92%',
                      color: AppColors.grade5,
                      delay: 800,
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
}

/// Topic card for math topics grid
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 48)),
                    const Gap(8),
                    Text(
                      title,
                      style: AppTextStyles.heading4.copyWith(
                        color: AppColors.textPrimary,
                      ),
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
                begin: Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                delay: Duration(milliseconds: delay),
                curve: Curves.easeOutBack,
              ),
    );
  }
}

/// Stat card for displaying stats
class _StatCard extends StatelessWidget {
  const _StatCard({
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
          padding: const EdgeInsets.all(12),
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
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
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
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          delay: Duration(milliseconds: delay),
        );
  }
}
