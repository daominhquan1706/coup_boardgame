import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../data/provider/game_provider.dart';

class GameStartController extends GetxController {
  final GameProvider? provider;
  GameStartController({this.provider});

  final _text = 'GameStart'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  //get firebase service
  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  late StreamSubscription? _roomStreamSubscription;

  final Rx<CoupRoomModel?> currentRoom = Rx<CoupRoomModel?>(null);
  late Rx<CoupPlayerModel?> currentPlayer = Rx<CoupPlayerModel?>(null);

  late String roomCode;
  late String userName;

  // get room info
  Future<void> getRoomInfo(String roomId) async {
    EasyLoading.show(status: 'Starting...');
    final room = await _firestoreService.getRoom(roomId);
    currentPlayer.value = room.players.firstWhere((element) => element.name == userName);

    EasyLoading.dismiss();
    _roomStreamSubscription = _firestoreService.getRoomStream(roomCode).listen((value) {
      currentRoom.value = value;
      currentPlayer.value = value.players.firstWhere((element) => element.name == userName);
      if (value.roomState == GameState.waiting) {
        Get.offNamed(
          AppRoutes.lobbyRoom,
          parameters: {
            'roomCode': roomCode,
            'userName': userName,
          },
        );
      }
    });
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, String?>;
    roomCode = args['roomCode']!;
    userName = args['userName']!;
  }

  @override
  void onReady() {
    super.onReady();
    if (roomCode.isNotEmpty && userName.isNotEmpty) {
      getRoomInfo(roomCode);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    super.onClose();
    _roomStreamSubscription?.cancel();
  }

  //end game
  Future<void> endGame() async {
    await _firestoreService.endGame(roomCode);
  }
}
