import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/leaderboard_entry_entity.dart';

part 'leaderboard_entry_model.freezed.dart';
part 'leaderboard_entry_model.g.dart';

/// Data model for a leaderboard entry, matching the backend LeaderboardEntry.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class LeaderboardEntryModel with _$LeaderboardEntryModel {
  const factory LeaderboardEntryModel({
    @JsonKey(name: 'user_id') required String userId,
    required String username,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'total_points') required int totalPoints,
    required int rank,
  }) = _LeaderboardEntryModel;

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryModelFromJson(json);
}

/// Extension methods for converting between LeaderboardEntryModel and LeaderboardEntryEntity.
extension LeaderboardEntryModelX on LeaderboardEntryModel {
  /// Converts this data model to a domain entity.
  LeaderboardEntryEntity toEntity() {
    return LeaderboardEntryEntity(
      userId: userId,
      username: username,
      displayName: displayName,
      totalPoints: totalPoints,
      rank: rank,
    );
  }
}
