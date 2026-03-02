import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/xp_profile_entity.dart';
import '../../domain/entities/xp_award_result_entity.dart';
import 'xp_profile_model.dart';

part 'xp_award_result_model.freezed.dart';
part 'xp_award_result_model.g.dart';

/// Data model for XP award result, matching the backend XpAwardResponse.
@freezed
abstract class XpAwardResultModel with _$XpAwardResultModel {
  const factory XpAwardResultModel({
    @JsonKey(name: 'xp_awarded') required int xpAwarded,
    @JsonKey(name: 'total_xp') required int totalXp,
    @JsonKey(name: 'previous_level') required int previousLevel,
    @JsonKey(name: 'current_level') required int currentLevel,
    @JsonKey(name: 'leveled_up') required bool leveledUp,
    @JsonKey(name: 'xp_in_current_level') required int xpInCurrentLevel,
    @JsonKey(name: 'xp_for_next_level') required int xpForNextLevel,
    @JsonKey(name: 'newly_unlocked_achievements')
    required List<UnlockedAchievementModel> newlyUnlockedAchievements,
  }) = _XpAwardResultModel;

  factory XpAwardResultModel.fromJson(Map<String, dynamic> json) =>
      _$XpAwardResultModelFromJson(json);
}

/// Extension to convert [XpAwardResultModel] to domain entity.
extension XpAwardResultModelX on XpAwardResultModel {
  XpAwardResultEntity toEntity() {
    return XpAwardResultEntity(
      xpAwarded: xpAwarded,
      totalXp: totalXp,
      previousLevel: previousLevel,
      currentLevel: currentLevel,
      leveledUp: leveledUp,
      xpInCurrentLevel: xpInCurrentLevel,
      xpForNextLevel: xpForNextLevel,
      newlyUnlockedAchievements: newlyUnlockedAchievements
          .map((a) => a.toEntity())
          .toList(),
    );
  }
}
