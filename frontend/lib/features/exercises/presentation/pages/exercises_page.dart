import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gradient_background.dart';

/// Exercises page showing math categories with difficulty levels.
class ExercisesPage extends ConsumerWidget {
  const ExercisesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      _CategoryData(
        emoji: '➕',
        name: 'Addition',
        color: AppColors.grade1,
        topic: 'addition',
      ),
      _CategoryData(
        emoji: '➖',
        name: 'Subtraction',
        color: AppColors.grade2,
        topic: 'subtraction',
      ),
      _CategoryData(
        emoji: '✖️',
        name: 'Multiplication',
        color: AppColors.grade3,
        topic: 'multiplication',
      ),
      _CategoryData(
        emoji: '➗',
        name: 'Division',
        color: AppColors.grade4,
        topic: 'division',
      ),
    ];

    return GradientBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Math Exercises 📚', style: AppTextStyles.heading2)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms),
              const Gap(8),
              Text(
                    'Choose a category and difficulty level',
                    style: AppTextStyles.body2,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 100.ms),
              const Gap(20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const Gap(16),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryCard(
                    data: category,
                    delay: 200 + (index * 100),
                    onDifficultySelected: (difficulty) {
                      context.push(
                        RouteNames.exerciseTopicPath
                          .replaceFirst(':topic', category.topic)
                          .replaceFirst(':difficulty', difficulty),
                      );
                    },
                  );
                },
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for category info
class _CategoryData {
  final String emoji;
  final String name;
  final Color color;
  final String topic;

  _CategoryData({
    required this.emoji,
    required this.name,
    required this.color,
    required this.topic,
  });
}

/// Category card with expandable difficulty levels
class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.data,
    required this.delay,
    required this.onDifficultySelected,
  });

  final _CategoryData data;
  final int delay;
  final Function(String) onDifficultySelected;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: widget.data.color.withValues(alpha: 0.08),
            border: Border.all(
              color: widget.data.color.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleExpand,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        widget.data.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data.name,
                              style: AppTextStyles.heading4,
                            ),
                            const Gap(4),
                            Text(
                              'Tap to see difficulty levels',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _expandController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _expandController.value * 3.14159,
                            child: Icon(
                              Icons.expand_more,
                              color: widget.data.color,
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _expandController,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: widget.data.color.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _DifficultyButton(
                        label: 'Easy 🌟',
                        color: AppColors.success,
                        onTap: () => widget.onDifficultySelected('easy'),
                      ),
                      const Gap(8),
                      _DifficultyButton(
                        label: 'Medium ⭐⭐',
                        color: AppColors.warning,
                        onTap: () => widget.onDifficultySelected('medium'),
                      ),
                      const Gap(8),
                      _DifficultyButton(
                        label: 'Hard 🌟🌟🌟',
                        color: AppColors.error,
                        onTap: () => widget.onDifficultySelected('hard'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: widget.delay),
        )
        .slideX(
          begin: -0.2,
          end: 0,
          duration: 600.ms,
          delay: Duration(milliseconds: widget.delay),
        );
  }
}

/// Difficulty button
class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
