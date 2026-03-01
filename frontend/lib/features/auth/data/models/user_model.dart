import '../../domain/entities/user_entity.dart';

/// Data model for user, matching the backend UserResponse.
///
/// This is a plain Dart class (not Freezed) that represents user data
/// as returned from the API, with JSON serialization support.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.gradeLevel,
    this.age,
    this.role = 'student',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique user identifier.
  final String id;

  /// User's email address.
  final String email;

  /// User's username.
  final String username;

  /// User's display name (may differ from username).
  final String? displayName;

  /// URL to the user's avatar image.
  final String? avatarUrl;

  /// User's current grade level (1-6).
  final int gradeLevel;

  /// User's age in years.
  final int? age;

  /// User's role (e.g., 'student', 'parent', 'admin').
  final String role;

  /// Whether the user account is active.
  final bool isActive;

  /// When this user account was created.
  final DateTime? createdAt;

  /// When this user account was last updated.
  final DateTime? updatedAt;

  /// Creates a UserModel from JSON data.
  ///
  /// Handles snake_case keys from the backend API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      gradeLevel: json['grade_level'] as int? ?? 0,
      age: json['age'] as int?,
      role: json['role'] as String? ?? 'student',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Creates a UserModel from a UserEntity.
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      username: entity.username,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      gradeLevel: entity.gradeLevel,
      role: entity.role,
    );
  }

  /// Converts this model to JSON data.
  ///
  /// Uses snake_case keys for API compatibility.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'grade_level': gradeLevel,
      'age': age,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

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

  /// Creates a copy of this model with optionally modified fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? gradeLevel,
    int? age,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      age: age ?? this.age,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ username.hashCode;

  @override
  String toString() => 'UserModel(id: $id, username: $username, email: $email)';
}
