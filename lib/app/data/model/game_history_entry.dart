class GameHistoryEntry {
  final String id;
  final String eventType;
  final String actorName;
  final String actionType;
  final String? targetName;
  final String? claimedCard;
  final int? coinDelta;
  final String? status;
  final DateTime? createdAt;

  const GameHistoryEntry({
    required this.id,
    required this.eventType,
    required this.actorName,
    required this.actionType,
    this.targetName,
    this.claimedCard,
    this.coinDelta,
    this.status,
    this.createdAt,
  });
}
