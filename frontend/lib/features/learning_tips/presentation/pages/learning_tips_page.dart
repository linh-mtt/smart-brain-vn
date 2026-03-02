import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../domain/entities/learning_tip_entity.dart';
import '../../domain/entities/tip_progress_entity.dart';
import '../notifiers/learning_tips_notifier.dart';
import '../providers/learning_tips_providers.dart';

/// A page that displays a list of learning tips with filtering and progress tracking.
class LearningTipsPage extends ConsumerStatefulWidget {
  const LearningTipsPage({super.key});

  @override
  ConsumerState<LearningTipsPage> createState() => _LearningTipsPageState();
}

class _LearningTipsPageState extends ConsumerState<LearningTipsPage> {
  @override
  void initState() {
    super.initState();
    // Load tips when the page first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningTipsListProvider.notifier).loadTips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learningTipsListProvider);

    return GradientBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(state),
            const SizedBox(height: 16),
            _buildCategoryFilters(state),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LearningTipsListState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Learning Tips 💡',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!state.isLoading && state.tips.isNotEmpty)
            _buildProgressBadge(state.completedCount, state.tips.length),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(int completed, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$completed/$total',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildCategoryFilters(LearningTipsListState state) {
    final categories = <Map<String, String?>>[
      {'id': null, 'label': 'All'},
      {'id': 'addition', 'label': 'Addition ➕'},
      {'id': 'multiplication', 'label': 'Multiplication ✖️'},
      {'id': 'mental_math', 'label': 'Mental Math 🧠'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: categories.map((cat) {
          final isSelected = state.selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                cat['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(learningTipsListProvider.notifier)
                    .filterByCategory(cat['id']);
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.disabled,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildBody(LearningTipsListState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.filteredTips.isEmpty) {
      return Center(
        child: Text(
          'No tips found in this category.',
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: state.filteredTips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tip = state.filteredTips[index];
        final progress = state.progressMap[tip.id];
        return TipCard(
              tip: tip,
              progress: progress,
              onTap: () async {
                await context.pushNamed(
                  RouteNames.tipDetail,
                  pathParameters: {'tipId': tip.id},
                );
                // Refresh progress when returning
                ref.read(learningTipsListProvider.notifier).refreshProgress();
              },
            )
            .animate(delay: (100 * index).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text('Oops! Something went wrong.', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(learningTipsListProvider.notifier).loadTips();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.tip,
    this.progress,
    required this.onTap,
  });

  final LearningTipEntity tip;
  final TipProgressEntity? progress;
  final VoidCallback onTap;

  Color get _tipColor {
    try {
      return Color(int.parse(tip.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress?.isCompleted ?? false;
    final quizScore = progress?.quizScore;
    final quizTotal = progress?.quizTotal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _tipColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored bar
                Container(width: 6, color: _tipColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon container
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _tipColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tip.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title and description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tip.title,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tip.description,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Footer: Difficulty + Progress
                        Row(
                          children: [
                            _buildDifficultyStars(tip.difficulty),
                            const Spacer(),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      quizScore != null
                                          ? 'Score: $quizScore/$quizTotal'
                                          : 'Completed',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().scale(
                                curve: Curves.elasticOut,
                                duration: 600.ms,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyStars(int difficulty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < difficulty ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }
}
