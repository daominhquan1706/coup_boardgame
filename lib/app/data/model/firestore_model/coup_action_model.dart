import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coup_action_model.g.dart';

enum CoupActionType {
  income,
  foreignAid,
  coup,
  tax,
  assassinate,
  exchange,
  steal,
  challenge,
  blockForeignAid,
  blockAssassinate,
  blockSteal,
  blockExchange,
  blockCoup,
  blockTax,
  blockIncome,
  blockChallenge,
  blockBlockForeignAid,
  blockBlockAssassinate,
  blockBlockSteal,
  blockBlockExchange,
  blockBlockCoup,
  blockBlockTax,
  blockBlockIncome,
  blockBlockChallenge,
}

@JsonSerializable()
class ActionModel implements BaseModel {
  final CoupPlayer source; // Player performing the action
  final CoupActionType actionType; // Type of action being taken (e.g., income, challenge)
  final CoupPlayer? target; // Optional target player if the action requires one

  ActionModel({required this.source, required this.actionType, this.target});

  factory ActionModel.fromJson(Map<String, dynamic> json) => _$ActionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActionModelToJson(this);
}
