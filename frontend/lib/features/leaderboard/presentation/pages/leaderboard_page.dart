import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../providers/leaderboard_providers.dart';

/// Leaderboard page showing ranked students.
///
/// Features:
/// - Top 3 with special styling (gold/silver/bronze)
/// - Tab bar for different time periods (Weekly/Monthly/All Time)
/// - Current user highlighted
/// - Smooth animations and kid-friendly design
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage();

  /// Generates a consistent color from a userId hash.
  static Color _colorFromUserId(String userId) {
    final hash = userId.hashCode;
    final colors = [
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFFFF6B6B),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Leaderboard', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      child: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _TabBar(),
          ),
          // Leaderboard content
          Expanded(
            child: leaderboardAsync.when(
              loading: () => _buildLoadingView(),
              error: (error, stack) => _buildErrorView(ref, error),
              data: (entries) =>
                  _buildLeaderboardContent(context, ref, entries),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const Gap(16),
          Text('Loading leaderboard...', style: AppTextStyles.body2),
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
              'Could not load leaderboard.',
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
              onPressed: () => ref.invalidate(leaderboardProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(
    BuildContext context,
    WidgetRef ref,
    List<LeaderboardEntryModel> entries,
  ) {
    final currentUser = ref.watch(authNotifierProvider).value;
    final currentUserId = currentUser?.id;

    // Build display entries
    final displayEntries = entries.map((e) {
      final initials = e.username.length >= 2
          ? e.username.substring(0, 2).toUpperCase()
          : e.username.toUpperCase();
      return _DisplayEntry(
        rank: e.rank,
        name: e.displayName ?? e.username,
        initials: initials,
        avatarColor: _colorFromUserId(e.userId),
        score: e.totalPoints,
        isCurrentUser: e.userId == currentUserId,
      );
    }).toList();

    if (displayEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const Gap(16),
            Text(
              'No entries yet!',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final topThree = displayEntries.where((e) => e.rank <= 3).toList();
    final rest = displayEntries.where((e) => e.rank > 3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Top 3 special display
          if (topThree.length >= 3)
            _TopThreeWidget(entries: topThree.take(3).toList()),
          const Gap(24),
          // Rest of leaderboard
          ...rest.asMap().entries.map(
            (entry) => _LeaderboardEntryWidget(
              entry: entry.value,
              delay: Duration(milliseconds: 200 + (entry.key * 100)),
            ),
          ),
          const Gap(24),
        ],
      ),
    );
  }
}

/// Simple display model for leaderboard entry widgets.
class _DisplayEntry {
  final int rank;
  final String name;
  final String initials;
  final Color avatarColor;
  final int score;
  final bool isCurrentUser;

  const _DisplayEntry({
    required this.rank,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.score,
    this.isCurrentUser = false,
  });
}

/// Top 3 leaderboard entries with special styling.
class _TopThreeWidget extends StatelessWidget {
  const _TopThreeWidget({required this.entries});

  final List<_DisplayEntry> entries;

  String _getMedalEmoji(int rank) => switch (rank) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  Color _getMedalColor(int rank) => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFCD7F32),
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    // Arrange as 2, 1, 3 for visual pyramid
    final sorted = [entries[1], entries[0], entries[2]];
    final positions = [0.5, 0.0, 1.5];

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(3, (index) {
          final entry = sorted[index];
          final position = positions[index];

          return Positioned(
            left: MediaQuery.of(context).size.width * 0.25 * position,
            bottom: 20 * (1 - (entry.rank - 1).abs() / 2),
            child:
                _TopThreeCard(
                      entry: entry,
                      medalColor: _getMedalColor(entry.rank),
                      medal: _getMedalEmoji(entry.rank),
                    )
                    .animate()
                    .scaleXY(
                      begin: 0.6,
                      end: 1.0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: const Duration(milliseconds: 600)),
          );
        }),
      ),
    );
  }
}

/// Card for top 3 positions.
class _TopThreeCard extends StatelessWidget {
  const _TopThreeCard({
    required this.entry,
    required this.medalColor,
    required this.medal,
  });

  final _DisplayEntry entry;
  final Color medalColor;
  final String medal;

  @override
  Widget build(BuildContext context) {
    final cardWidth = entry.rank == 1 ? 100.0 : 80.0;

    return SizedBox(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: const TextStyle(fontSize: 36)),
          const Gap(8),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [entry.avatarColor, entry.avatarColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: medalColor, width: 3),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: entry.rank == 1 ? 18 : 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(8),
          Text(
            entry.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: entry.rank == 1 ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(4),
          Text(
            '${entry.score} pts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: medalColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual leaderboard entry widget.
class _LeaderboardEntryWidget extends StatelessWidget {
  const _LeaderboardEntryWidget({required this.entry, required this.delay});

  final _DisplayEntry entry;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: entry.isCurrentUser
                ? AppColors.secondary.withOpacity(0.15)
                : AppColors.surface,
            border: Border.all(
              color: entry.isCurrentUser
                  ? AppColors.secondary
                  : AppColors.divider,
              width: entry.isCurrentUser ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${entry.rank}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        entry.avatarColor,
                        entry.avatarColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      entry.initials,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                // Name
                Expanded(
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.score}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: delay)
        .slideX(
          begin: 0.5,
          end: 0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: const Duration(milliseconds: 400));
  }
}

/// Tab bar for time period selection.
class _TabBar extends ConsumerWidget {
  static const _tabs = ['Weekly', 'Monthly', 'All Time'];
  static const _periods = ['weekly', 'monthly', 'all_time'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(leaderboardPeriodProvider);
    final selectedIndex = _periods.indexOf(currentPeriod);

    return Row(
      children: List.generate(_tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              ref.read(leaderboardPeriodProvider.notifier).setPeriod(_periods[index]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.secondary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
