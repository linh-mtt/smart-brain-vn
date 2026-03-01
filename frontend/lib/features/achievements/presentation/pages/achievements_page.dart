import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../data/models/achievement_model.dart';
import '../providers/achievement_providers.dart';

/// Page displaying achievement badges in a grid layout.
///
/// Shows both unlocked badges with colors and animations,
/// and locked badges in grayscale with lock overlay.
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Achievements', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      child: achievementsAsync.when(
        loading: () => _buildLoadingShimmer(),
        error: (error, stack) => _buildErrorView(ref, error),
        data: (achievements) => _buildAchievementsGrid(achievements),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Unlock badges by reaching milestones! 🌟',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surface,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: const Duration(milliseconds: 1200),
                    color: AppColors.primary.withOpacity(0.1),
                  );
            },
          ),
        ],
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
              'Oops! Could not load achievements.',
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
              onPressed: () => ref.invalidate(achievementsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(List<AchievementModel> achievements) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Unlock badges by reaching milestones! 🌟',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return _AchievementBadgeWidget(
                badge: achievements[index],
                delay: Duration(milliseconds: 100 * index),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual achievement badge widget.
class _AchievementBadgeWidget extends StatelessWidget {
  const _AchievementBadgeWidget({required this.badge, required this.delay});

  final AchievementModel badge;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Can add badge details sheet here
      },
      child: _buildBadgeContent()
          .animate(delay: delay)
          .scaleXY(
            begin: 0.8,
            end: 1.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: const Duration(milliseconds: 400)),
    );
  }

  Widget _buildBadgeContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Badge background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: badge.isUnlocked
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 48,
                    color: badge.isUnlocked ? Colors.white : Colors.white70,
                  ),
                ),
                const Gap(12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: badge.isUnlocked ? Colors.white : Colors.white70,
                      height: 1.2,
                    ),
                  ),
                ),
                const Gap(6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: badge.isUnlocked
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white54,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lock overlay for locked badges
          if (!badge.isUnlocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
