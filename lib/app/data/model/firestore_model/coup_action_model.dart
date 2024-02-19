import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coup_action_model.g.dart';


@JsonSerializable()
class ActionModel implements BaseModel {
  final CoupPlayerModel source; // Player performing the action
  final CoupActionType actionType; // Type of action being taken (e.g., income, challenge)
  final CoupPlayerModel? target; // Optional target player if the action requires one

  ActionModel({required this.source, required this.actionType, this.target});

  factory ActionModel.fromJson(Map<String, dynamic> json) => _$ActionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActionModelToJson(this);
}
