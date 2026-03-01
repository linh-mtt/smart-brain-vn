/// Domain entity representing a user.
///
/// This is a plain Dart class (not Freezed) that represents the
/// core user concept in the domain layer, independent of data sources.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.gradeLevel,
    required this.role,
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

  /// User's role (e.g., 'student', 'parent', 'admin').
  final String role;

  /// Returns the display name, falling back to username.
  String get effectiveDisplayName => displayName ?? username;

  /// Returns the user's initials for avatar placeholder.
  String get initials {
    final name = effectiveDisplayName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Whether this user is a student.
  bool get isStudent => role == 'student';

  /// Whether this user is a parent.
  bool get isParent => role == 'parent';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, username: $username, grade: $gradeLevel)';

  /// Creates a copy with modified fields.
  UserEntity copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? gradeLevel,
    String? role,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      role: role ?? this.role,
    );
  }
}
