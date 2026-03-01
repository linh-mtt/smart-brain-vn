import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/topic_progress_entity.dart';

part 'topic_progress_model.freezed.dart';
part 'topic_progress_model.g.dart';

/// Data model for topic progress, matching the backend TopicProgressResponse.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class TopicProgressModel with _$TopicProgressModel {
  const factory TopicProgressModel({
    required String topic,
    @JsonKey(name: 'mastery_score') required double masteryScore,
    @JsonKey(name: 'total_answered') required int totalAnswered,
    @JsonKey(name: 'correct_count') required int correctCount,
    @JsonKey(name: 'recent_scores') required List<bool> recentScores,
  }) = _TopicProgressModel;

  factory TopicProgressModel.fromJson(Map<String, dynamic> json) =>
      _$TopicProgressModelFromJson(json);
}

/// Extension methods for converting between TopicProgressModel and TopicProgressEntity.
extension TopicProgressModelX on TopicProgressModel {
  /// Converts this data model to a domain entity.
  TopicProgressEntity toEntity() {
    return TopicProgressEntity(
      topic: topic,
      masteryScore: masteryScore,
      totalAnswered: totalAnswered,
      correctCount: correctCount,
      recentScores: recentScores,
    );
  }
}
