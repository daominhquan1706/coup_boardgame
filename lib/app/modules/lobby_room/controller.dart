import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../data/provider/lobby_room_provider.dart';

class LobbyRoomController extends GetxController {
  final LobbyRoomProvider? provider;
  LobbyRoomController({this.provider});

  final _text = 'LobbyRoom'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  String? get roomCode => Get.parameters['roomCode'] ?? '';
  // user name
  String? get userName => Get.parameters['userName'] ?? '';

  final Rx<CoupRoomModel?> room = Rx<CoupRoomModel?>(null);

  late StreamSubscription? _roomStreamSubscription;

  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  bool get isHost => room.value?.hostId == userName;

  bool get canStart => (room.value?.players.length ?? 0) >= 2;

  @override
  void onReady() {
    super.onReady();
    if (roomCode != null && userName != null) {
      _firestoreService.getRoom(roomCode!).then((value) {
        room.value = value;
      });

      _roomStreamSubscription = _firestoreService.getRoomStream(roomCode!).listen((value) {
        room.value = value;
        if (value.roomState == GameState.playing) {
          Get.offNamed(
            AppRoutes.gameStart,
            arguments: {
              'roomCode': roomCode,
              'userName': userName,
            },
          );
        }
      });

      _firestoreService.joinRoom(
        roomCode!,
        CoupPlayerModel(
          name: userName!,
          isReady: true,
          cards: [],
          isAlive: true,
          coins: 2,
          isBot: false,
        ),
      );
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    super.onClose();
    _roomStreamSubscription?.cancel();
  }

  //start game
  Future<void> startGame() async {
    if (!isHost) {
      EasyLoading.showError('Only host can start game');
      return;
    }

    if (!canStart) {
      EasyLoading.showError('Need at least 2 players');
      return;
    }

    if (room.value?.players.every((element) => element.isReady) == true) {
      await _firestoreService.startGame(roomCode!);
    } else {
      EasyLoading.showError('All players must be ready');
    }
  }

  Future<void> copyCode() async {
    await Clipboard.setData(ClipboardData(text: roomCode!));
    EasyLoading.showSuccess('Room code copied', duration: const Duration(milliseconds: 500));
  }

  Future<void> addAI() async {
    if (!isHost) {
      EasyLoading.showError('Only host can add bot players');
      return;
    }

    await _firestoreService.addBot(roomCode!);
  }

  Future<void> removeAI() async {
    if (!isHost) {
      EasyLoading.showError('Only host can remove bot players');
      return;
    }

    await _firestoreService.removeBot(roomCode!);
  }
}
