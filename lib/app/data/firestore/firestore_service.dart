import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coup_boardgame/app/data/api/api_error.dart';
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

      await _firestore.collection('rooms').doc(roomId).update(
            (room
                  ..deck = listCards
                  ..players = players
                  ..roomState = GameState.playing)
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
}
