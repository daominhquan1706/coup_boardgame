import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../data/provider/game_provider.dart';

class GameStartController extends GetxController {
  final GameProvider? provider;
  GameStartController({this.provider});

  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  final Rx<CoupRoomModel?> currentRoom = Rx<CoupRoomModel?>(null);
  final Rx<CoupPlayerModel?> mePlayer = Rx<CoupPlayerModel?>(null);

  StreamSubscription<CoupRoomModel>? _roomStreamSubscription;

  late final String roomCode;
  late final String userName;

  bool _isProcessingBots = false;

  CoupPlayerModel? get currentPlayerTurn {
    final room = currentRoom.value;
    if (room == null) return null;
    return room.players.firstWhereOrNull((element) => element.name == room.currentTurn);
  }

  bool get isMyTurn => currentPlayerTurn?.name == userName;

  bool get canAct {
    final room = currentRoom.value;
    if (room == null) return false;
    return room.roomState == GameState.playing && room.phase == GamePhase.action && isMyTurn;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, String?>;
    roomCode = args['roomCode'] ?? '';
    userName = args['userName'] ?? '';
  }

  @override
  void onReady() {
    super.onReady();
    if (roomCode.isEmpty || userName.isEmpty) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    _subscribeRoom();
  }

  @override
  void onClose() {
    _roomStreamSubscription?.cancel();
    super.onClose();
  }

  void _subscribeRoom() {
    EasyLoading.show(status: 'Loading game...');
    _roomStreamSubscription = _firestoreService.getRoomStream(roomCode).listen((room) async {
      currentRoom.value = room;
      mePlayer.value = room.players.firstWhereOrNull((element) => element.name == userName);

      EasyLoading.dismiss();

      if (room.roomState == GameState.waiting) {
        Get.offNamed(
          AppRoutes.lobbyRoom,
          parameters: {
            'roomCode': roomCode,
            'userName': userName,
          },
        );
        return;
      }

      if (room.roomState == GameState.finished && room.winnerId != null) {
        EasyLoading.showInfo('Winner: ${room.winnerId}');
      }

      await _processBots(room);
    });
  }

  Future<void> _processBots(CoupRoomModel room) async {
    if (_isProcessingBots) return;
    _isProcessingBots = true;
    try {
      await _firestoreService.processBots(room.roomId);
    } finally {
      _isProcessingBots = false;
    }
  }

  Future<void> endGame() async {
    await _firestoreService.endGame(roomCode);
  }

  Future<void> performAction(CoupActionType action) async {
    if (!canAct) {
      EasyLoading.showInfo('Not your turn');
      return;
    }

    CoupPlayerModel? targetPlayer;
    if (CoupFunction.isNeedPlayerTarget(action)) {
      targetPlayer = await _buildDialogTargetPlayer();
      if (targetPlayer == null) return;
    }

    final player = mePlayer.value;
    if (player == null) return;

    final actionModel = CoupActionModel(
      source: player,
      target: targetPlayer,
      actionType: action,
    );

    try {
      await _firestoreService.performAction(roomCode, actionModel);
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  Future<void> passChallenge() async {
    await _firestoreService.respondToChallenge(roomCode, userName, challenge: false);
  }

  Future<void> challengeAction() async {
    await _firestoreService.respondToChallenge(roomCode, userName, challenge: true);
  }

  Future<void> passBlockOpportunity() async {
    await _firestoreService.respondToBlockOpportunity(roomCode, userName, block: false);
  }

  Future<void> blockAction(String claimedCard) async {
    await _firestoreService.respondToBlockOpportunity(
      roomCode,
      userName,
      block: true,
      claimedCard: claimedCard,
    );
  }

  Future<void> passBlockChallenge() async {
    await _firestoreService.respondToBlockChallenge(roomCode, userName, challenge: false);
  }

  Future<void> challengeBlock() async {
    await _firestoreService.respondToBlockChallenge(roomCode, userName, challenge: true);
  }

  Future<CoupPlayerModel?> _buildDialogTargetPlayer() async {
    final room = currentRoom.value;
    if (room == null) return null;

    return Get.dialog<CoupPlayerModel>(
      AlertDialog(
        title: const Text('Select Target Player'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: room.players
                .where((player) => player.name != userName && player.isAlive)
                .map(
                  (player) => ListTile(
                    title: Text(player.name),
                    onTap: () => Get.back(result: player),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
