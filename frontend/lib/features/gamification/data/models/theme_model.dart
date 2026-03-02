import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/xp_profile_entity.dart';

part 'theme_model.freezed.dart';
part 'theme_model.g.dart';

/// Data model for a theme, matching the backend ThemeResponse.
@freezed
abstract class ThemeModel with _$ThemeModel {
  const factory ThemeModel({
    required String id,
    required String name,
    required String description,
    required String emoji,
    @JsonKey(name: 'required_level') required int requiredLevel,
    @JsonKey(name: 'required_xp') required int requiredXp,
    @JsonKey(name: 'is_premium') required bool isPremium,
    @JsonKey(name: 'is_unlocked') required bool isUnlocked,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'can_unlock') required bool canUnlock,
  }) = _ThemeModel;

  factory ThemeModel.fromJson(Map<String, dynamic> json) =>
      _$ThemeModelFromJson(json);
}

/// Extension to convert [ThemeModel] to domain entity.
extension ThemeModelX on ThemeModel {
  ThemeEntity toEntity() {
    return ThemeEntity(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      requiredLevel: requiredLevel,
      requiredXp: requiredXp,
      isPremium: isPremium,
      isUnlocked: isUnlocked,
      isActive: isActive,
      canUnlock: canUnlock,
    );
  }
}
