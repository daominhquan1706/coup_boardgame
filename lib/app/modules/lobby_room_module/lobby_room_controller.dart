import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../app/data/provider/lobby_room_provider.dart';

class LobbyRoomController extends GetxController {
  final LobbyRoomProvider? provider;
  LobbyRoomController({this.provider});

  final _text = 'LobbyRoom'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  String get roomCode => Get.parameters['roomCode']!;

  final Rx<CoupRoomModel?> room = Rx<CoupRoomModel?>(null);

  late StreamSubscription? _roomStreamSubscription;

  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  @override
  void onReady() {
    super.onReady();

    _firestoreService.getRoom(roomCode).then((value) {
      room.value = value;
    });

    _roomStreamSubscription = _firestoreService.getRoomStream(roomCode).listen(room.call);

    _firestoreService.addPlayerToRoom(
      roomCode,
      CoupPlayer(
        name: Get.parameters['userName'] ?? '',
        cards: [],
        isHost: true,
      ),
    );
  }

  @override
  void onClose() {
    super.onClose();
    _roomStreamSubscription?.cancel();
  }

  //start game
  void startGame() {
    if (room.value?.players.every((element) => element.isReady) == true) {
      Get.toNamed(
        AppRoutes.gameStart,
        parameters: {
          'userName': Get.parameters['userName'] ?? '',
          'roomCode': roomCode,
        },
      );
    } else {
      EasyLoading.showError('All players must be ready');
    }
  }

  Future<void> copyCode() async {
    await Clipboard.setData(ClipboardData(text: roomCode));
    EasyLoading.showSuccess('Room code copied', duration: const Duration(milliseconds: 500));
  }
}
