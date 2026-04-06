import 'dart:async';

import 'package:coup_boardgame/app/constants/local_storage_keys.dart';
import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/provider/lobby_room_provider.dart';

class LobbyRoomController extends GetxController {
  final LobbyRoomProvider? provider;
  LobbyRoomController({this.provider});

  final _text = 'LobbyRoom'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  final GetStorage _storage = GetStorage();

  String get roomCode =>
      (Get.parameters['room_code'] ?? Get.parameters['roomCode'] ?? '').trim();
  // stable player id
  String get userName => (_storage.read<String>(LocalStorageKeys.userName) ??
          Get.parameters['userName'] ??
          '')
      .trim();
  String get defaultDisplayName =>
      _storage.read<String>(LocalStorageKeys.displayName) ??
      Get.parameters['displayName'] ??
      'Player';
  bool get shouldAutoReadyOnEnter => Get.parameters['autoReady'] == '1';

  final Rx<CoupRoomModel?> room = Rx<CoupRoomModel?>(null);
  final TextEditingController displayNameController = TextEditingController();
  final RxString _pendingDisplayName = ''.obs;

  late StreamSubscription? _roomStreamSubscription;
  Worker? _displayNameDebounceWorker;
  bool _didApplyAutoReady = false;
  bool _isUpdatingDisplayName = false;
  bool _shouldRetryDisplayNameSync = false;
  String _lastSubmittedDisplayName = '';
  bool _hasJoinedRoom = false;
  bool _isVerifyingMembership = false;
  bool _hasSeenMeInRoomStream = false;

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
  void onInit() {
    super.onInit();
    _displayNameDebounceWorker = debounce<String>(
      _pendingDisplayName,
      (_) => _syncMyDisplayName(),
      time: const Duration(seconds: 1),
    );
  }

  @override
  void onReady() {
    super.onReady();
    if (roomCode.isEmpty || userName.isEmpty) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }
    unawaited(_initializeLobby());
  }

  @override
  void onClose() {
    super.onClose();
    _roomStreamSubscription?.cancel();
    _displayNameDebounceWorker?.dispose();
    displayNameController.dispose();
  }

  //start game
  Future<void> startGame() async {
    if (!isHost) {
      AppToast.error('msgOnlyHostStart'.tr);
      return;
    }

    if (!canStart) {
      AppToast.error('msgAllPlayersReady'.tr);
      return;
    }

    await _firestoreService.startGame(roomCode);
  }

  Future<void> copyCode() async {
    await Clipboard.setData(ClipboardData(text: roomCode));
    AppToast.success('msgRoomCodeCopied'.tr,
        duration: const Duration(milliseconds: 900));
  }

  Future<void> addAI() async {
    if (!isHost) {
      AppToast.error('msgOnlyHostAddBot'.tr);
      return;
    }

    await _firestoreService.addBot(roomCode);
  }

  Future<void> toggleReady() async {
    if (isHost || userName.isEmpty) return;
    final roomState = room.value?.roomState;
    if (roomState != null && roomState != GameState.waiting) {
      AppToast.error('msgReadyUpdateFailed'.tr);
      return;
    }

    var currentReady = false;
    var isBot = false;
    final me = mePlayer;

    if (me != null) {
      currentReady = me.isReady;
      isBot = me.isBot;
    } else {
      try {
        final fresh = await _firestoreService.getPlayer(roomCode, userName);
        currentReady = fresh.isReady;
        isBot = fresh.isBot;
      } catch (_) {
        AppToast.error('msgReadyUpdateFailed'.tr);
        return;
      }
    }

    if (isBot) return;

    try {
      await _firestoreService.updatePlayerReady(
        roomCode,
        userName,
        isReady: !currentReady,
      );

      // Optimistic state update for faster UI response on guest devices.
      room.update((current) {
        final target = current?.players
            .firstWhereOrNull((player) => player.name == userName);
        if (target != null) {
          target.isReady = !currentReady;
        }
      });
      room.refresh();
    } catch (_) {
      AppToast.error('msgReadyUpdateFailed'.tr);
    }
  }

  void onDisplayNameChanged(String value) {
    _pendingDisplayName.value = value;
  }

  Future<void> updateMyDisplayName() async {
    await _syncMyDisplayName(showSuccessToast: true);
  }

  Future<void> _syncMyDisplayName({bool showSuccessToast = false}) async {
    if (_isUpdatingDisplayName) {
      _shouldRetryDisplayNameSync = true;
      return;
    }

    final me = mePlayer;
    if (me == null) return;

    final name = displayNameController.text.trim();
    if (name.isEmpty) {
      if (showSuccessToast) {
        AppToast.info('msgEnterName'.tr);
      }
      return;
    }
    if (name == _lastSubmittedDisplayName || name == me.shownName) {
      return;
    }

    _isUpdatingDisplayName = true;
    final success = await _firestoreService.updatePlayerDisplayName(
        roomCode, me.name, name);
    _isUpdatingDisplayName = false;
    if (_shouldRetryDisplayNameSync) {
      _shouldRetryDisplayNameSync = false;
      unawaited(_syncMyDisplayName());
    }
    if (!success) {
      // likely the game already started or transaction aborted
      AppToast.error('msgNameUpdateFailed'.tr);
      return;
    }

    // Optimistic UI update so the list reflects the new name immediately.
    room.update((current) {
      final target =
          current?.players.firstWhereOrNull((player) => player.name == me.name);
      if (target != null) {
        target.displayName = name;
      }
    });
    room.refresh();
    _lastSubmittedDisplayName = name;
    _storage.write(LocalStorageKeys.displayName, name);

    if (showSuccessToast) {
      AppToast.success('msgNameUpdated'.tr,
          duration: const Duration(milliseconds: 1000));
    }
  }

  Future<void> kickPlayer(String targetPlayerId) async {
    if (!isHost || userName.isEmpty) return;
    await _firestoreService.kickPlayer(
      roomCode,
      hostId: userName,
      targetPlayerId: targetPlayerId,
    );
  }

  Future<void> _initializeLobby() async {
    try {
      await _firestoreService.joinRoom(
        roomCode,
        CoupPlayerModel(
          name: userName,
          displayName: defaultDisplayName,
          isReady: false,
          cards: [],
          isAlive: true,
          coins: 2,
          isBot: false,
        ),
      );
      _hasJoinedRoom = true;
    } catch (_) {
      AppToast.error('msgFailedJoinRoom'.tr);
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    try {
      room.value = await _firestoreService.getRoom(roomCode);
    } catch (_) {
      // Stream below remains the source of truth.
    }

    _roomStreamSubscription =
        _firestoreService.getRoomStream(roomCode).listen((value) {
      room.value = value;

      final me =
          value.players.firstWhereOrNull((player) => player.name == userName);
      if (me == null) {
        // Avoid false "kicked" redirects during initial stream sync right after join.
        if (_hasJoinedRoom && _hasSeenMeInRoomStream) {
          unawaited(_verifyMembershipBeforeRedirect());
        }
        return;
      }
      _hasSeenMeInRoomStream = true;

      final shown = me.shownName;
      _lastSubmittedDisplayName = shown;
      if (displayNameController.text != shown) {
        displayNameController.text = shown;
      }

      if (shouldAutoReadyOnEnter &&
          !_didApplyAutoReady &&
          value.roomState == GameState.waiting) {
        _didApplyAutoReady = true;
        if (!me.isReady) {
          unawaited(_firestoreService.updatePlayerReady(roomCode, me.name,
              isReady: true));
        }
      }

      if (value.roomState == GameState.playing) {
        Get.offNamed(
          AppRoutes.gameStartPath(roomCode),
          arguments: {
            'roomCode': roomCode,
            'userName': userName,
          },
        );
      }
    });
  }

  Future<void> _verifyMembershipBeforeRedirect() async {
    if (_isVerifyingMembership || !_hasJoinedRoom) return;
    _isVerifyingMembership = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    var stillInRoom = false;
    try {
      await _firestoreService.getPlayer(roomCode, userName);
      stillInRoom = true;
    } catch (_) {
      stillInRoom = false;
    } finally {
      _isVerifyingMembership = false;
    }

    if (!stillInRoom && !isClosed) {
      AppToast.info('msgYouWereKicked'.tr);
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
