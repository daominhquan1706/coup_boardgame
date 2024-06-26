import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/utils/constants.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> createRoom(String roomId, List<String> players) async {
    try {
      final newRoom = CoupRoomModel(
        roomId: roomId,
        players: [],
        roomState: GameState.waiting,
        deck: [],
      );

      await _firestore.collection('rooms').doc(roomId).set(newRoom.toJson());

      Get.log('Room created successfully');
      return true;
    } catch (e) {
      Get.log('Failed to create room: $e');
      return false;
    }
  }

  // get room data
  Future<CoupRoomModel> getRoom(String roomId) async {
    final room = await _firestore.collection('rooms').doc(roomId).get();

    if (room.exists == false) {
      throw UnknownError();
    }

    return CoupRoomModel.fromJson(room.data()!);
  }

  Stream<CoupRoomModel> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((event) {
      return CoupRoomModel.fromJson(event.data()!);
    });
  }

  // Add a player to the room
  Future<bool> joinRoom(String roomId, CoupPlayerModel player) async {
    try {
      //add more player to players list, without overwriting the existing list
      final room = await getRoom(roomId);
      final players = room.players;
      // if player is already exist, override it
      if (players.any((element) => element.name == player.name)) {
        players.removeWhere((element) => element.name == player.name);
      }

      players.add(player);

      await _firestore.collection('rooms').doc(roomId).update({
        'players': players.map((e) => e.toJson()).toList(),
      });

      return true;
    } catch (e) {
      Get.log('Failed to add player to room: $e');
      return false;
    }
  }

  // check if can join room
  Future<bool> isCanJoinRoom(String roomId, String userName) async {
    final room = await _firestore.collection('rooms').doc(roomId).get();

    if (room.exists == false) {
      throw JoinRoomError('Room not found');
    }

    final data = room.data() as Map<String, dynamic>;
    final players = (data['players'] as List).map((e) => CoupPlayerModel.fromJson(e)).toList();

    if (players.length >= Constant.maxPlayersPerRoom) {
      throw JoinRoomError('Room is full');
      // checl name is already exist
    }

    if (players.isNotEmpty && players.any((element) => element.name == userName)) {
      throw JoinRoomError('Name is already exist');
    }

    return true;
  }

  // get user data by name
  Future<CoupPlayerModel> getPlayer(String roomId, String userName) async {
    final room = await _firestore.collection('rooms').doc(roomId).get();

    if (room.exists == false) {
      throw UnknownError();
    }

    final data = room.data() as Map<String, dynamic>;
    final players = (data['players'] as List).map((e) => CoupPlayerModel.fromJson(e)).toList();

    final player = players.firstWhere((element) => element.name == userName);

    return player;
  } // start game

  Future<void> startGame(String roomId) async {
    try {
      final room = await getRoom(roomId);
      final listCards = CoupFunction.generateDeck(room.players.length);
      final players = room.players
          .map(
            (e) => e
              ..cards = [
                listCards.removeLast(),
                listCards.removeLast(),
              ]
              ..isReady = false
              ..isAlive = true
              ..coins = 2,
          )
          .toList();

      final pickRandomPlayer = _pickRandom(players);

      await _firestore.collection('rooms').doc(roomId).update(
            (room
                  ..deck = listCards
                  ..players = players
                  ..roomState = GameState.playing
                  ..currentTurn = pickRandomPlayer.name)
                .toJson(),
          );
    } catch (e) {
      Get.log('Failed to start game: $e');
    }
  }

  // end game
  Future<void> endGame(String roomId) async {
    final room = await getRoom(roomId);

    final players = room.players
        .map(
          (e) => e
            ..cards = []
            ..isAlive = true
            ..coins = 2,
        )
        .toList();

    await _firestore.collection('rooms').doc(roomId).update(
          (room
                ..roomState = GameState.waiting
                ..players = players
                ..deck = [])
              .toJson(),
        );
  }

  void performAction(String roomCode, CoupActionModel actionModel) {
    if (actionModel.actionType == CoupActionType.income) {
      _performIncome(roomCode, actionModel);
    } else if (actionModel.actionType == CoupActionType.foreignAid) {
      _performForeignAid(roomCode, actionModel);
    } else if (actionModel.actionType == CoupActionType.taxByDuke) {
      _performTax(roomCode, actionModel);
    } else if (actionModel.actionType == CoupActionType.exchangeByAmbassador) {
      _performExchange(roomCode, actionModel);
    } else if (actionModel.actionType == CoupActionType.stealByCaptain) {
      _performSteal(roomCode, actionModel.source, actionModel);
    } else if (actionModel.actionType == CoupActionType.assassinate) {
      _performAssassinate(roomCode, actionModel.source, actionModel);
    } else if (actionModel.actionType == CoupActionType.coup) {
      _performCoup(roomCode, actionModel.source, actionModel);
    }
  }

  Future<void> _performIncome(String roomCode, CoupActionModel action) async {
    final player = action.source;
    final room = await getRoom(roomCode);
    final players = room.players;
    final index = players.indexOf(player);
    players[index] = player..coins += 1;

    _firestore.collection('rooms').doc(roomCode).update({
      'players': players.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _performForeignAid(String roomCode, CoupActionModel action) async {
    final player = action.source;
    final room = await getRoom(roomCode);
    final players = room.players;
    final index = players.indexOf(player);
    players[index] = player..coins += 2;

    _firestore.collection('rooms').doc(roomCode).update({
      'players': players.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _performTax(String roomCode, CoupActionModel actionModel) async {
    final player = actionModel.source;
    final room = await getRoom(roomCode);
    final players = room.players;
    final index = players.indexWhere((element) => element.name == player.name);
    players[index] = player..coins += 3;

    _firestore.collection('rooms').doc(roomCode).update({
      'players': players.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _performExchange(String roomCode, CoupActionModel actionModel) async {
    final player = actionModel.source;
    final room = await getRoom(roomCode);
    final players = room.players;
    final index = players.indexOf(player);
    final newDeck = room.deck;
    final newCards = [
      ...player.cards,
      newDeck.removeLast(),
      newDeck.removeLast(),
    ];

    players[index] = player..cards = newCards;

    _firestore.collection('rooms').doc(roomCode).update({
      'players': players.map((e) => e.toJson()).toList(),
      'deck': room.deck.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> _performSteal(String roomCode, CoupPlayerModel source, CoupActionModel actionModel) {
    throw UnimplementedError();
  }

  Future<void> _performAssassinate(
      String roomCode, CoupPlayerModel source, CoupActionModel actionModel) {
    throw UnimplementedError();
  }

  Future<void> _performCoup(String roomCode, CoupPlayerModel source, CoupActionModel actionModel) {
    throw UnimplementedError();
  }

  CoupPlayerModel _pickRandom(List<CoupPlayerModel> players) {
    final random = Random();
    final index = random.nextInt(players.length);
    return players[index];
  }
}
