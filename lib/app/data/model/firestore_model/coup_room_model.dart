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
  finished,
}

extension GameStateExtension on GameState {
  String get name {
    switch (this) {
      case GameState.waiting:
        return 'waiting';
      case GameState.playing:
        return 'playing';
      case GameState.finished:
        return 'finished';
    }
  }

  static GameState fromName(String value) {
    switch (value) {
      case 'waiting':
        return GameState.waiting;
      case 'playing':
        return GameState.playing;
      case 'finished':
        return GameState.finished;
      default:
        return GameState.waiting;
    }
  }
}

enum GamePhase {
  waiting,
  action,
  challenge,
  block,
  blockChallenge,
  resolve,
  finished,
}

extension GamePhaseX on GamePhase {
  String get name {
    switch (this) {
      case GamePhase.waiting:
        return 'waiting';
      case GamePhase.action:
        return 'action';
      case GamePhase.challenge:
        return 'challenge';
      case GamePhase.block:
        return 'block';
      case GamePhase.blockChallenge:
        return 'block_challenge';
      case GamePhase.resolve:
        return 'resolve';
      case GamePhase.finished:
        return 'finished';
    }
  }

  static GamePhase fromName(String value) {
    switch (value) {
      case 'waiting':
        return GamePhase.waiting;
      case 'action':
        return GamePhase.action;
      case 'challenge':
        return GamePhase.challenge;
      case 'block':
        return GamePhase.block;
      case 'block_challenge':
        return GamePhase.blockChallenge;
      case 'resolve':
        return GamePhase.resolve;
      case 'finished':
        return GamePhase.finished;
      default:
        return GamePhase.waiting;
    }
  }
}

@JsonSerializable()
class CoupRoomModel implements BaseModel {
  String roomId;
  List<CoupPlayerModel> players;
  @JsonKey(fromJson: _gameStateFromJson, toJson: _gameStateToJson, name: 'status')
  GameState roomState;
  @JsonKey(fromJson: _gamePhaseFromJson, toJson: _gamePhaseToJson)
  GamePhase phase;
  @JsonKey(includeIfNull: false)
  String? hostId;
  CoupActionType? lastAction;
  List<CoupCardModel> deck;
  @JsonKey(includeIfNull: false, name: 'currentTurnPlayerId')
  String? currentTurn;
  @JsonKey(includeIfNull: false)
  String? winnerId;
  List<String> playerOrder;
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
    this.phase = GamePhase.waiting,
    required this.deck,
    this.hostId,
    this.lastAction,
    this.currentTurn,
    this.winnerId,
    this.playerOrder = const <String>[],
    this.currentAction,
  });

  factory CoupRoomModel.fromJson(Map<String, dynamic> json) => _$CoupRoomModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupRoomModelToJson(this);
}

GameState _gameStateFromJson(String? value) {
  return GameStateExtension.fromName(value ?? 'waiting');
}

String _gameStateToJson(GameState value) {
  return value.name;
}

GamePhase _gamePhaseFromJson(String? value) {
  return GamePhaseX.fromName(value ?? 'waiting');
}

String _gamePhaseToJson(GamePhase value) {
  return value.name;
}
