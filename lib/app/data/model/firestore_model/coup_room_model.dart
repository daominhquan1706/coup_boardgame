import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:json_annotation/json_annotation.dart';


part 'coup_room_model.g.dart'; 
enum GameState {
  waiting,
  playing,
  finished,
}

@JsonSerializable()
class CoupRoomModel implements BaseModel {
  String roomId;
  List<CoupPlayer> players;
  GameState roomState;
  CoupActionType? lastAction;

  CoupRoomModel({
    required this.roomId,
    required this.players,
    required this.roomState,
    this.lastAction,
  });

  factory CoupRoomModel.fromJson(Map<String, dynamic> json) => _$CoupRoomModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupRoomModelToJson(this);
}
