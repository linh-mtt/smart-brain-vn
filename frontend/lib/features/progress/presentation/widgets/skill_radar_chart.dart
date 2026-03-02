import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/topic_progress_entity.dart';

/// Radar chart displaying skill breakdown across topics.
///
/// Each axis represents a topic (addition, subtraction, multiplication, division)
/// with mastery scores mapped to radar entries.
class SkillRadarChart extends StatelessWidget {
  const SkillRadarChart({super.key, required this.topicProgress});

  /// Topic progress data to display.
  final List<TopicProgressEntity> topicProgress;

  static const _topicOrder = [
    'addition',
    'subtraction',
    'multiplication',
    'division',
  ];

  static const _topicLabels = {
    'addition': '➕ Add',
    'subtraction': '➖ Sub',
    'multiplication': '✖️ Mul',
    'division': '➗ Div',
  };

  static const _topicColors = [
    AppColors.grade1,
    AppColors.grade2,
    AppColors.grade3,
    AppColors.grade4,
  ];

  @override
  Widget build(BuildContext context) {
    final orderedTopics = _getOrderedTopics();
    if (orderedTopics.isEmpty) {
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
          Text('Skill Breakdown', style: AppTextStyles.heading4),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.2,
            child: RadarChart(
              _buildChartData(orderedTopics),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(orderedTopics),
        ],
      ),
    );
  }

  List<_TopicEntry> _getOrderedTopics() {
    final entries = <_TopicEntry>[];
    for (var i = 0; i < _topicOrder.length; i++) {
      final topic = _topicOrder[i];
      final data = topicProgress.where((t) => t.topic == topic).firstOrNull;
      entries.add(
        _TopicEntry(
          topic: topic,
          label: _topicLabels[topic] ?? topic,
          color: _topicColors[i],
          mastery: data?.masteryScore ?? 0,
          accuracy: data?.accuracyRate ?? 0,
        ),
      );
    }
    return entries;
  }

  RadarChartData _buildChartData(List<_TopicEntry> entries) {
    return RadarChartData(
      radarBorderData: BorderSide(color: AppColors.divider, width: 1),
      titlePositionPercentageOffset: 0.2,
      titleTextStyle: AppTextStyles.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      getTitle: (index, angle) {
        if (index < 0 || index >= entries.length) {
          return RadarChartTitle(text: '');
        }
        return RadarChartTitle(text: entries[index].label, angle: angle);
      },
      dataSets: [
        // Mastery scores
        RadarDataSet(
          dataEntries: entries
              .map((e) => RadarEntry(value: e.mastery))
              .toList(),
          fillColor: AppColors.primary.withValues(alpha: 0.2),
          borderColor: AppColors.primary,
          borderWidth: 2.5,
          entryRadius: 3,
        ),
        // Accuracy scores
        RadarDataSet(
          dataEntries: entries
              .map((e) => RadarEntry(value: e.accuracy))
              .toList(),
          fillColor: AppColors.success.withValues(alpha: 0.15),
          borderColor: AppColors.success,
          borderWidth: 2,
          entryRadius: 3,
        ),
      ],
      tickCount: 4,
      tickBorderData: BorderSide(
        color: AppColors.divider.withValues(alpha: 0.5),
        width: 1,
      ),
      ticksTextStyle: AppTextStyles.caption.copyWith(
        fontSize: 9,
        color: AppColors.textHint,
      ),
      radarShape: RadarShape.polygon,
    );
  }

  Widget _buildLegend(List<_TopicEntry> entries) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppColors.primary, label: 'Mastery'),
        _LegendItem(color: AppColors.success, label: 'Accuracy'),
      ],
    );
  }
}

class _TopicEntry {
  const _TopicEntry({
    required this.topic,
    required this.label,
    required this.color,
    required this.mastery,
    required this.accuracy,
  });

  final String topic;
  final String label;
  final Color color;
  final double mastery;
  final double accuracy;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

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
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
