import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../notifiers/auth_notifier.dart';
import '../widgets/grade_selector.dart';

/// User profile page displaying account info and stats.
///
/// Shows avatar (with initials placeholder), display name,
/// grade level badge, and action buttons.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return GradientBackground(
      child: SafeArea(
        child: authState.when(
          loading: () => const AppLoading(message: 'Loading profile...'),
          error: (error, stack) => AppErrorWidget(
            message: 'Oops! Couldn\'t load your profile.',
            onRetry: () =>
                ref.read(authNotifierProvider.notifier).refreshProfile(),
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 64)),
                    const Gap(16),
                    Text('Not logged in', style: AppTextStyles.heading3),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: () => context.go(RouteNames.loginPath),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Gap(16),

                  // Avatar
                  _buildAvatar(user.displayName ?? user.username),

                  const Gap(16),

                  // Name
                  Text(
                    user.displayName ?? user.username,
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

                  const Gap(4),

                  Text(
                    '@${user.username}',
                    style: AppTextStyles.body2,
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),

                  const Gap(8),

                  // Grade badge
                  _buildGradeBadge(user.gradeLevel),
                  const Gap(32),

                  // Stats cards
                  _buildStatsRow()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const Gap(32),

                  // Action buttons
                  _buildActionButtons(context, ref),

                  const Gap(24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = _getInitials(name);
    return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 300.ms);
  }

  Widget _buildGradeBadge(int gradeLevel) {
    final color = AppColors.gradeColor(gradeLevel);
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '🎓 Grade $gradeLevel',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 350.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '⭐',
            value: '0',
            label: 'Points',
            color: AppColors.warning,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            emoji: '🏆',
            value: '1',
            label: 'Level',
            color: AppColors.primary,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            emoji: '🔥',
            value: '0',
            label: 'Streak',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Edit Profile
        _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () => _showEditProfileSheet(context, ref),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 500.ms)
            .slideX(begin: -0.1, end: 0),

        const Gap(12),

        // Achievements
        _ActionTile(
              icon: Icons.emoji_events_outlined,
              label: 'Achievements',
              onTap: () => context.push(RouteNames.achievementsPath),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 550.ms)
            .slideX(begin: -0.1, end: 0),

        const Gap(12),

        // Settings
        _ActionTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push(RouteNames.settingsPath),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 600.ms)
            .slideX(begin: -0.1, end: 0),

        const Gap(12),

        // Parent Dashboard
        _ActionTile(
              icon: Icons.family_restroom_outlined,
              label: 'Parent Dashboard',
              onTap: () => context.push(RouteNames.parentDashboardPath),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 650.ms)
            .slideX(begin: -0.1, end: 0),

        const Gap(24),

        // Logout
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out?'),
                  content: const Text(
                    'Are you sure you want to log out? You\'ll need to sign in again next time.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authNotifierProvider.notifier).logout();
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Log Out',
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 700.ms),
      ],
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    final user = authState.value;
    if (user == null) return;

    final nameController = TextEditingController(
      text: user.displayName ?? user.username,
    );
    int selectedGrade = user.gradeLevel;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(20),
                  Text('Edit Profile', style: AppTextStyles.heading3),
                  const Gap(24),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
                  ),
                  const Gap(24),
                  GradeSelector(
                    selectedGrade: selectedGrade,
                    onGradeSelected: (grade) {
                      setSheetState(() => selectedGrade = grade);
                    },
                  ),
                  const Gap(24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(authNotifierProvider.notifier)
                            .updateProfile(
                              displayName: nameController.text.trim(),
                              gradeLevel: selectedGrade,
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated! ✨'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Save Changes', style: AppTextStyles.button),
                    ),
                  ),
                  const Gap(8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Stats card displaying a metric with emoji.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Gap(2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Action tile for profile menu items.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const Gap(16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
