import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coup_action_model.g.dart';

@JsonSerializable()
class CoupActionModel implements BaseModel {
  @JsonKey(includeIfNull: false)
  final String? actionId;
  final CoupPlayerModel source; // Player performing the action
  final CoupActionType actionType; // Type of action being taken (e.g., income, challenge)
  final CoupPlayerModel? target; // Optional target player if the action requires one
  @JsonKey(includeIfNull: false)
  String? status;
  @JsonKey(includeIfNull: false)
  String? claimedCard;
  @JsonKey(includeIfNull: false)
  String? challengerId;
  @JsonKey(includeIfNull: false)
  String? blockerId;
  @JsonKey(includeIfNull: false)
  String? blockClaimedCard;
  List<String> listNeedVote = []; // List of players who need to vote on the action
  List<String> listVoted = []; // List of players who have voted on the action
  String? preventedBy; // Name of the player who prevented the action
  bool? isFakeAction; // Whether the action is a fake action

  CoupActionModel({
    this.actionId,
    required this.source,
    required this.actionType,
    this.target,
    this.status,
    this.claimedCard,
    this.challengerId,
    this.blockerId,
    this.blockClaimedCard,
  });

  factory CoupActionModel.fromJson(Map<String, dynamic> json) => _$CoupActionModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupActionModelToJson(this);
}
