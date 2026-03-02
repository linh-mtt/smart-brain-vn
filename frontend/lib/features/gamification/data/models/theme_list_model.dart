import 'package:freezed_annotation/freezed_annotation.dart';

import 'theme_model.dart';

part 'theme_list_model.freezed.dart';
part 'theme_list_model.g.dart';

/// Data model for the themes list response from the backend.
@freezed
abstract class ThemeListModel with _$ThemeListModel {
  const factory ThemeListModel({
    required List<ThemeModel> themes,
    @JsonKey(name: 'active_theme_id') String? activeThemeId,
  }) = _ThemeListModel;

  factory ThemeListModel.fromJson(Map<String, dynamic> json) =>
      _$ThemeListModelFromJson(json);
}
