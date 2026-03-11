class GameHistoryEntry {
  final String id;
  final String actorName;
  final String actionType;
  final String? targetName;
  final String? claimedCard;
  final String? status;
  final DateTime? createdAt;

  const GameHistoryEntry({
    required this.id,
    required this.actorName,
    required this.actionType,
    this.targetName,
    this.claimedCard,
    this.status,
    this.createdAt,
  });
}
