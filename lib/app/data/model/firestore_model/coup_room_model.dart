import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coup_room_model.g.dart';

enum GameState {
  waiting,
  playing,
}

extension GameStateExtension on GameState {
  String get name {
    switch (this) {
      case GameState.waiting:
        return 'waiting';
      case GameState.playing:
        return 'playing';
    }
  }
}

@JsonSerializable()
class CoupRoomModel implements BaseModel {
  String roomId;
  List<CoupPlayerModel> players;
  GameState roomState;
  CoupActionType? lastAction;
  List<CoupCardModel> deck;
  String? currentTurn;
  CoupActionModel? currentAction;

  CoupPlayerModel get currentPlayerTurn {
    final playersAliveInRoom = players.where((player) => player.isAlive).toList();

    return playersAliveInRoom.firstWhere((element) => element.name == currentTurn);
  }

  List<CoupPlayerModel> get playersAlive {
    return players.where((player) => player.isAlive).toList();
  }

  int get voteNeeded {
    return playersAlive.length - 1;
  }

  bool get isWaitingVote {
    return (currentAction?.listVoted.length ?? 0) < voteNeeded;
  }

  bool get isFullyVoted {
    return isWaitingVote == false;
  }

  CoupRoomModel({
    required this.roomId,
    required this.players,
    required this.roomState,
    required this.deck,
    this.lastAction,
  });

  factory CoupRoomModel.fromJson(Map<String, dynamic> json) => _$CoupRoomModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupRoomModelToJson(this);
}
