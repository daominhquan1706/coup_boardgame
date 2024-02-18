import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/coup_player_model.dart';

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

class ActionModel implements IModel {
  final CoupPlayer source; // Player performing the action
  final CoupActionType actionType; // Type of action being taken (e.g., income, challenge)
  final CoupPlayer? target; // Optional target player if the action requires one

  ActionModel({required this.source, required this.actionType, this.target});

  @override
  Map<String, dynamic> toJson() {
    return {
      'source': source.toJson(),
      'actionType': actionType.toString(),
      'target': target?.toJson(),
    };
  }

  factory ActionModel.fromJson(Map<String, dynamic> json) {
    return ActionModel(
      source: CoupPlayer.fromJson(json['source']),
      actionType: CoupActionType.values.firstWhere((e) => e.toString() == json['actionType']),
      target: json['target'] != null ? CoupPlayer.fromJson(json['target']) : null,
    );
  }
}
