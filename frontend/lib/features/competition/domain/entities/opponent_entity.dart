/// Represents an opponent in a competition match.
class OpponentEntity {
  const OpponentEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.eloRating,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int eloRating;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpponentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
