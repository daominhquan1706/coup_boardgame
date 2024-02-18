
import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/coup_player_model.dart';

enum GameState {
  waiting,
  playing,
  finished,
}

class CoupRoomModel implements IModel{
  String roomId;
  String roomName;
  List<CoupPlayer> players;
  GameState roomState;
  CoupActionType? lastAction;


  CoupRoomModel({
    required this.roomId,
    required this.roomName,
    required this.players,
    required this.roomState,
    this.lastAction,
  });

  // to json 
  @override
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'players': players.map((e) => e.toJson()).toList(),
      'roomState': roomState.toString(),
      'lastAction': lastAction?.toString(),
    };
  }

  // from json
  factory CoupRoomModel.fromJson(Map<String, dynamic> json) {
    return CoupRoomModel(
      roomId: json['roomId'],
      roomName: json['roomName'],
      players: (json['players'] as List).map((e) => CoupPlayer.fromJson(e)).toList(),
      roomState: GameState.values.firstWhere((e) => e.toString() == json['roomState']),
      lastAction: json['lastAction'] != null ? CoupActionType.values.firstWhere((e) => e.toString() == json['lastAction']) : null,
    );
  }
}
