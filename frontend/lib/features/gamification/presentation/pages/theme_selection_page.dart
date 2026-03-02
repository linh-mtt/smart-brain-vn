import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/xp_profile_entity.dart';
import '../providers/gamification_providers.dart';

class ThemeSelectionPage extends ConsumerStatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  ConsumerState<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends ConsumerState<ThemeSelectionPage> {
  @override
  void initState() {
    super.initState();
    // Load data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationNotifierProvider.notifier).loadThemes();
      ref.read(gamificationNotifierProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gamificationNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Shop 🎨'), centerTitle: true),
      body: Builder(
        builder: (context) {
          if (state.isLoadingThemes) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading themes...', style: textTheme.bodyLarge),
                ],
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong.',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      state.error.toString(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(gamificationNotifierProvider.notifier)
                          .loadThemes();
                      ref
                          .read(gamificationNotifierProvider.notifier)
                          .loadProfile();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state.themes.isEmpty) {
            return Center(
              child: Text(
                'No themes available yet.',
                style: textTheme.bodyLarge,
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Adjust based on content height
            ),
            itemCount: state.themes.length,
            itemBuilder: (context, index) {
              final themeItem = state.themes[index];
              return _ThemeCard(
                    themeEntity: themeItem,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  )
                  .animate(delay: (100 * index).ms)
                  .fadeIn()
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          );
        },
      ),
    );
  }
}

class _ThemeCard extends ConsumerWidget {
  const _ThemeCard({
    required this.themeEntity,
    required this.colorScheme,
    required this.textTheme,
  });

  final ThemeEntity themeEntity;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = !themeEntity.isUnlocked;
    final isActive = themeEntity.isActive;

    // Determine card background color
    final cardColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainer;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Emoji Header
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      themeEntity.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),

                // Theme Info
                Text(
                  themeEntity.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  themeEntity.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Action Button or Status
                _buildActionButton(ref),
              ],
            ),
          ),

          // Premium Badge
          if (themeEntity.isPremium)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

          // Active Badge
          if (isActive)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),

          // Level Requirement Badge (if locked)
          if (isLocked)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${themeEntity.requiredLevel}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Lock Overlay
          if (isLocked && !themeEntity.canUnlock)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(WidgetRef ref) {
    if (themeEntity.isActive) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'Active',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (themeEntity.isUnlocked) {
      return FilledButton(
        onPressed: () {
          ref
              .read(gamificationNotifierProvider.notifier)
              .activateTheme(themeEntity.id);
        },
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        child: const Text('Activate'),
      );
    }

    if (themeEntity.canUnlock) {
      return FilledButton.tonal(
        onPressed: () {
          ref
              .read(gamificationNotifierProvider.notifier)
              .unlockTheme(themeEntity.id);
        },
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
        child: const Text('Unlock'),
      );
    }

    // Locked state
    return Center(
      child: Text(
        'Locked',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
