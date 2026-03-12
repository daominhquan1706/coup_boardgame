import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
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
  // stable player id
  String? get userName => Get.parameters['userName'] ?? '';
  String get defaultDisplayName => Get.parameters['displayName'] ?? 'Player';
  bool get shouldAutoReadyOnEnter => Get.parameters['autoReady'] == '1';

  final Rx<CoupRoomModel?> room = Rx<CoupRoomModel?>(null);
  final TextEditingController displayNameController = TextEditingController();

  late StreamSubscription? _roomStreamSubscription;
  bool _didApplyAutoReady = false;

  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  bool get isHost => room.value?.hostId == userName;

  CoupPlayerModel? get mePlayer =>
      room.value?.players.firstWhereOrNull((player) => player.name == userName);

  bool get canStart {
    final players = room.value?.players ?? <CoupPlayerModel>[];
    if (players.length < 2) return false;
    return players.every((player) => player.isBot ? true : player.isReady);
  }

  @override
  void onReady() {
    super.onReady();
    if ((roomCode ?? '').isNotEmpty && (userName ?? '').isNotEmpty) {
      _firestoreService.getRoom(roomCode!).then((value) {
        room.value = value;
      });

      _roomStreamSubscription = _firestoreService.getRoomStream(roomCode!).listen((value) {
        room.value = value;

        final me = value.players.firstWhereOrNull((player) => player.name == userName);
        if (me == null) {
          EasyLoading.showInfo('msgYouWereKicked'.tr);
          Get.offAllNamed(AppRoutes.home);
          return;
        }

        final shown = me.shownName;
        if (displayNameController.text != shown) {
          displayNameController.text = shown;
        }

        if (shouldAutoReadyOnEnter && !_didApplyAutoReady && value.roomState == GameState.waiting) {
          _didApplyAutoReady = true;
          if (!me.isReady) {
            unawaited(_firestoreService.updatePlayerReady(roomCode!, me.name, isReady: true));
          }
        }

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
          displayName: defaultDisplayName,
          isReady: false,
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
    displayNameController.dispose();
  }

  //start game
  Future<void> startGame() async {
    if (!isHost) {
      EasyLoading.showError('msgOnlyHostStart'.tr);
      return;
    }

    if (!canStart) {
      EasyLoading.showError('msgAllPlayersReady'.tr);
      return;
    }

    await _firestoreService.startGame(roomCode!);
  }

  Future<void> copyCode() async {
    await Clipboard.setData(ClipboardData(text: roomCode!));
    EasyLoading.showSuccess('msgRoomCodeCopied'.tr, duration: const Duration(milliseconds: 500));
  }

  Future<void> addAI() async {
    if (!isHost) {
      EasyLoading.showError('msgOnlyHostAddBot'.tr);
      return;
    }

    await _firestoreService.addBot(roomCode!);
  }

  Future<void> toggleReady() async {
    final me = mePlayer;
    if (me == null || me.isBot || isHost) return;
    await _firestoreService.updatePlayerReady(
      roomCode!,
      me.name,
      isReady: !me.isReady,
    );
  }

  Future<void> updateMyDisplayName() async {
    final me = mePlayer;
    if (me == null) return;

    final name = displayNameController.text.trim();
    if (name.isEmpty) {
      EasyLoading.showInfo('msgEnterName'.tr);
      return;
    }

    final success = await _firestoreService.updatePlayerDisplayName(roomCode!, me.name, name);
    if (!success) {
      // likely the game already started or transaction aborted
      EasyLoading.showError('msgNameUpdateFailed'.tr);
      return;
    }

    // Optimistic UI update so the list reflects the new name immediately.
    room.update((current) {
      final target = current?.players.firstWhereOrNull((player) => player.name == me.name);
      if (target != null) {
        target.displayName = name;
      }
    });
    room.refresh();

    EasyLoading.showSuccess('msgNameUpdated'.tr, duration: const Duration(milliseconds: 700));
  }

  Future<void> kickPlayer(String targetPlayerId) async {
    if (!isHost || userName == null) return;
    await _firestoreService.kickPlayer(
      roomCode!,
      hostId: userName!,
      targetPlayerId: targetPlayerId,
    );
  }
}
