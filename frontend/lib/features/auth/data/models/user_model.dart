import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data model for user, matching the backend UserResponse.
///
/// Uses Freezed for immutability and code generation.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String username,
    String? displayName,
    String? avatarUrl,
    required int gradeLevel,
    int? age,
    @Default('student') String role,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Extension methods for converting between UserModel and UserEntity.
extension UserModelX on UserModel {
  /// Converts this data model to a domain entity.
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      gradeLevel: gradeLevel,
      role: role,
    );
  }
}
