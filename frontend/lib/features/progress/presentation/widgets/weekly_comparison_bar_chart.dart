import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/weekly_comparison_entity.dart';

/// Bar chart displaying weekly comparison data.
///
/// Shows grouped bars for this week vs last week, with day labels on X axis.
class WeeklyComparisonBarChart extends StatelessWidget {
  const WeeklyComparisonBarChart({super.key, required this.data});

  /// Weekly comparison data.
  final WeeklyComparisonEntity data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Weekly Comparison', style: AppTextStyles.heading4),
              ),
              _buildImprovementBadge(),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildImprovementBadge() {
    final isImproved = data.improvementPercent >= 0;
    final color = isImproved ? AppColors.success : AppColors.error;
    final icon = isImproved ? '📈' : '📉';
    final sign = isImproved ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$icon $sign${data.improvementPercent.toStringAsFixed(1)}%',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BarChartData _buildChartData() {
    final maxLen = data.days.length;

    // Find max value for Y axis
    double maxY = 0;
    for (final v in data.thisWeek) {
      if (v > maxY) maxY = v;
    }
    for (final v in data.lastWeek) {
      if (v > maxY) maxY = v;
    }
    maxY = ((maxY / 10).ceil() * 10).toDouble().clamp(10, double.infinity);

    return BarChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppColors.divider, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= maxLen) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  data.days[index],
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      maxY: maxY,
      barGroups: List.generate(maxLen, (i) {
        final thisWeekVal = i < data.thisWeek.length ? data.thisWeek[i] : 0.0;
        final lastWeekVal = i < data.lastWeek.length ? data.lastWeek[i] : 0.0;

        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: thisWeekVal,
              color: AppColors.primary,
              width: 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: lastWeekVal,
              color: AppColors.primaryLight,
              width: 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
          barsSpace: 4,
        );
      }),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.85),
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final label = rodIndex == 0 ? 'This week' : 'Last week';
            return BarTooltipItem(
              '$label\n${rod.toY.toStringAsFixed(0)}',
              AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.primary, label: 'This Week'),
        const SizedBox(width: 24),
        _LegendDot(color: AppColors.primaryLight, label: 'Last Week'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
