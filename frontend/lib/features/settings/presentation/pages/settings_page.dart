import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_math_kids/core/constants/app_colors.dart';
import 'package:smart_math_kids/core/constants/app_text_styles.dart';
import 'package:smart_math_kids/core/router/route_names.dart';
import 'package:smart_math_kids/core/widgets/gradient_background.dart';
import 'package:smart_math_kids/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:smart_math_kids/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_math_kids/features/settings/presentation/providers/settings_providers.dart';

/// Settings page for user preferences and account management.
///
/// Features:
/// - Account settings showing user info from auth state
/// - Preferences (sound, notifications, dark mode toggles) persisted via Hive
/// - Learning section (language, grade level) persisted via Hive
/// - About section
/// - Logout button
class SettingsPage extends ConsumerWidget {
  const SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return GradientBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Account section
            _SettingsSection(
              title: 'Account',
              children: [
                _SettingsTile(
                  icon: Icons.person,
                  title: 'Profile Name',
                  subtitle:
                      currentUser?.displayName ??
                      currentUser?.username ??
                      'Your Learning Name',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: currentUser?.email ?? 'Not signed in',
                  onTap: () {},
                ),
              ],
            ),
            const Gap(24),

            // Preferences section
            _SettingsSection(
              title: 'Preferences',
              children: [
                _SettingsToggleTile(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  subtitle: 'Play sounds during activities',
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleSound(value);
                  },
                ),
                _SettingsToggleTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Get daily practice reminders',
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleNotifications(value);
                  },
                ),
                _SettingsToggleTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: settings.darkModeEnabled
                      ? 'Dark theme active'
                      : 'Light theme active',
                  value: settings.darkModeEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDarkMode(value);
                  },
                ),
              ],
            ),
            const Gap(24),

            // Learning section
            _SettingsSection(
              title: 'Learning',
              children: [
                _SettingsDropdownTile(
                  icon: Icons.language,
                  title: 'Language',
                  value: settings.language,
                  options: const ['English', 'Spanish', 'French'],
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setLanguage(value);
                  },
                ),
                _SettingsDropdownTile(
                  icon: Icons.school,
                  title: 'Grade Level',
                  value: settings.gradeLevel,
                  options: const [
                    'Grade 1',
                    'Grade 2',
                    'Grade 3',
                    'Grade 4',
                    'Grade 5',
                    'Grade 6',
                  ],
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setGradeLevel(value);
                  },
                ),
              ],
            ),
            const Gap(24),

            // About section
            _SettingsSection(
              title: 'About',
              children: [
                _SettingsTile(
                  icon: Icons.info,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our policies',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Contact us anytime',
                  onTap: () {},
                ),
              ],
            ),
            const Gap(32),

            // Logout button
            SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        // Call logout
                        await ref.read(authNotifierProvider.notifier).logout();

                        if (context.mounted) {
                          // Navigate to login page
                          context.go(RouteNames.loginPath);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Logout', style: AppTextStyles.button),
                  ),
                )
                .animate()
                .slideX(
                  begin: 0.5,
                  end: 0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: const Duration(milliseconds: 400)),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}

/// Section header for settings groups.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading4,
        ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
        const Gap(12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: children.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.divider, indent: 56),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    );
  }
}

/// Settings tile with icon and text.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body1),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings tile with toggle switch.
class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.disabled,
              size: 24,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.textPrimary : AppColors.disabled,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: enabled ? AppColors.textHint : AppColors.disabled,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

/// Settings tile with dropdown selector.
class _SettingsDropdownTile extends StatelessWidget {
  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body1),
                const Gap(4),
                DropdownButton<String>(
                  value: value,
                  items: options
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                  underline: const SizedBox.shrink(),
                  isDense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
