import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// A visual grade level picker with animated selection cards.
///
/// Displays grades 1-6 as colorful cards that animate on selection.
/// Each card shows the grade number and age range.
class GradeSelector extends StatelessWidget {
  const GradeSelector({
    super.key,
    required this.selectedGrade,
    required this.onGradeSelected,
  });

  /// The currently selected grade (null if none selected).
  final int? selectedGrade;

  /// Callback when a grade is selected.
  final void Function(int grade) onGradeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Your Grade', style: AppTextStyles.heading4),
        const SizedBox(height: 8),
        Text(
          'Pick the grade that matches your school level',
          style: AppTextStyles.body2,
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final grade = index + 1;
            final isSelected = selectedGrade == grade;
            final color = AppColors.gradeColor(grade);
            final ageRange = _getAgeRange(grade);

            return _GradeCard(
                  grade: grade,
                  ageRange: ageRange,
                  color: color,
                  isSelected: isSelected,
                  onTap: () => onGradeSelected(grade),
                )
                .animate(delay: (index * 80).ms)
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
          },
        ),
      ],
    );
  }

  String _getAgeRange(int grade) => switch (grade) {
    1 => 'Ages 6-7',
    2 => 'Ages 7-8',
    3 => 'Ages 8-9',
    4 => 'Ages 9-10',
    5 => 'Ages 10-11',
    6 => 'Ages 11-12',
    _ => '',
  };
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.ageRange,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final int grade;
  final String ageRange;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 44 : 36,
              height: isSelected ? 44 : 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$grade',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grade $grade',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ageRange,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 18,
              ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.elasticOut,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
