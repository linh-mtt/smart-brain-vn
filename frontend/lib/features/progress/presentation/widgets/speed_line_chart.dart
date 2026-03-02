import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/chart_data_point_entity.dart';

/// Line chart displaying speed (response time) history over time.
///
/// Shows a curved gradient-filled line in orange tones with touch tooltips.
class SpeedLineChart extends StatelessWidget {
  const SpeedLineChart({super.key, required this.dataPoints});

  /// Speed data points sorted by date (value = response time in seconds).
  final List<ChartDataPointEntity> dataPoints;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text('Speed Trend', style: AppTextStyles.heading4),
          const SizedBox(height: 4),
          Text('Lower is faster ⚡', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final sorted = List<ChartDataPointEntity>.from(dataPoints)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].value));
    }

    final maxY = sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minY = sorted.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final yPadding = (maxY - minY) * 0.15;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _yInterval(minY, maxY),
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
            interval: _bottomInterval(sorted.length),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= sorted.length) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('d/M').format(sorted[index].date),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _yInterval(minY, maxY),
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  '${value.toStringAsFixed(1)}s',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (sorted.length - 1).toDouble(),
      minY: (minY - yPadding).clamp(0, double.infinity),
      maxY: maxY + yPadding,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.85),
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItems: (spots) => spots.map((spot) {
            final index = spot.x.toInt();
            final date = index < sorted.length
                ? DateFormat('MMM d').format(sorted[index].date)
                : '';
            return LineTooltipItem(
              '$date\n${spot.y.toStringAsFixed(1)}s',
              AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: AppColors.secondary,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.3),
                AppColors.secondary.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  double _yInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    return (range / 5).ceilToDouble();
  }

  double _bottomInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    return (dataLength / 5).ceilToDouble();
  }
}
