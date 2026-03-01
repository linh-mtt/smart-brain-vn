import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/achievement_entity.dart';

part 'achievement_model.freezed.dart';
part 'achievement_model.g.dart';

/// Data model for achievement, matching the backend AchievementResponse.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class AchievementModel with _$AchievementModel {
  const factory AchievementModel({
    required String id,
    required String name,
    required String description,
    required String emoji,
    @JsonKey(name: 'reward_points') required int rewardPoints,
    @JsonKey(name: 'is_unlocked') required bool isUnlocked,
    @JsonKey(name: 'unlocked_at') DateTime? unlockedAt,
  }) = _AchievementModel;

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      _$AchievementModelFromJson(json);
}

/// Extension methods for converting between AchievementModel and AchievementEntity.
extension AchievementModelX on AchievementModel {
  /// Converts this data model to a domain entity.
  AchievementEntity toEntity() {
    return AchievementEntity(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      rewardPoints: rewardPoints,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
    );
  }
}
