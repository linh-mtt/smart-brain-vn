import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/xp_profile_entity.dart';
import 'theme_model.dart';

part 'xp_profile_model.freezed.dart';
part 'xp_profile_model.g.dart';

/// Data model for an unlocked achievement from the backend.
@freezed
abstract class UnlockedAchievementModel with _$UnlockedAchievementModel {
  const factory UnlockedAchievementModel({
    required String id,
    required String name,
    required String description,
    required String emoji,
    @JsonKey(name: 'reward_points') required int rewardPoints,
    @JsonKey(name: 'unlocked_at') required DateTime unlockedAt,
  }) = _UnlockedAchievementModel;

  factory UnlockedAchievementModel.fromJson(Map<String, dynamic> json) =>
      _$UnlockedAchievementModelFromJson(json);
}

/// Data model for a user's XP profile, matching the backend XpProfileResponse.
@freezed
abstract class XpProfileModel with _$XpProfileModel {
  const factory XpProfileModel({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'total_xp') required int totalXp,
    @JsonKey(name: 'current_level') required int currentLevel,
    @JsonKey(name: 'xp_in_current_level') required int xpInCurrentLevel,
    @JsonKey(name: 'xp_for_next_level') required int xpForNextLevel,
    @JsonKey(name: 'xp_progress_percent') required double xpProgressPercent,
    @JsonKey(name: 'unlocked_achievements')
    required List<UnlockedAchievementModel> unlockedAchievements,
    @JsonKey(name: 'active_theme') ThemeModel? activeTheme,
  }) = _XpProfileModel;

  factory XpProfileModel.fromJson(Map<String, dynamic> json) =>
      _$XpProfileModelFromJson(json);
}

/// Extension to convert [UnlockedAchievementModel] to domain entity.
extension UnlockedAchievementModelX on UnlockedAchievementModel {
  UnlockedAchievementEntity toEntity() {
    return UnlockedAchievementEntity(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      rewardPoints: rewardPoints,
      unlockedAt: unlockedAt,
    );
  }
}

/// Extension to convert [XpProfileModel] to domain entity.
extension XpProfileModelX on XpProfileModel {
  XpProfileEntity toEntity() {
    return XpProfileEntity(
      userId: userId,
      totalXp: totalXp,
      currentLevel: currentLevel,
      xpInCurrentLevel: xpInCurrentLevel,
      xpForNextLevel: xpForNextLevel,
      xpProgressPercent: xpProgressPercent,
      unlockedAchievements: unlockedAchievements
          .map((a) => a.toEntity())
          .toList(),
      activeTheme: activeTheme?.toEntity(),
    );
  }
}
