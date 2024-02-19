import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/utils/constants.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> createRoom(String roomId, List<String> players) async {
    try {
      final newRoom = CoupRoomModel(
        roomId: roomId,
        players: [],
        roomState: GameState.waiting,
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
  Future<bool> addPlayerToRoom(String roomId, CoupPlayer player) async {
    try {
      //add more player to players list, without overwriting the existing list
      await _firestore.collection('rooms').doc(roomId).update({
        'players': FieldValue.arrayUnion([player.toJson()])
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
    final players = (data['players'] as List).map((e) => CoupPlayer.fromJson(e)).toList();

    if (players.length >= Constant.maxPlayersPerRoom) {
      throw JoinRoomError('Room is full');
      // checl name is already exist
    }

    if (players.isNotEmpty && players.any((element) => element.name == userName)) {
      throw JoinRoomError('Name is already exist');
    }

    return true;
  }

  // ready
  Future<void> ready(String roomId, String userName) async {
    // update field isReady of player in players list in room
    await _firestore.collection('rooms').doc(roomId).update({
      'players': FieldValue.arrayUnion([
        {
          'name': userName,
          'isReady': true,
        }
      ])
    });
  }
}
