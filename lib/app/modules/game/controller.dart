import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/game_history_entry.dart';
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
  final RxList<GameHistoryEntry> historyEntries = <GameHistoryEntry>[].obs;
  final RxInt autoActionCountdown = 0.obs;
  final RxBool autoActionEnabled = true.obs;

  StreamSubscription<CoupRoomModel>? _roomStreamSubscription;
  StreamSubscription<List<GameHistoryEntry>>? _historyStreamSubscription;
  Timer? _autoDecisionTimer;
  Timer? _countdownTicker;

  String roomCode = '';
  String userName = '';

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

  bool get isMeAlive => mePlayer.value?.isAlive ?? false;

  bool canRespondChallenge(CoupRoomModel room) {
    final action = room.currentAction;
    if (room.phase != GamePhase.challenge || action == null) return false;
    if (!isMeAlive) return false;
    if (action.source.name == userName) return false;
    return !action.listNeedVote.contains(userName);
  }

  bool canRespondBlock(CoupRoomModel room) {
    final action = room.currentAction;
    if (room.phase != GamePhase.block || action == null) return false;
    if (!isMeAlive) return false;
    if (action.listVoted.contains(userName)) return false;

    switch (action.actionType) {
      case CoupActionType.foreignAid:
        return action.source.name != userName;
      case CoupActionType.assassin:
      case CoupActionType.captain:
        return action.target?.name == userName;
      default:
        return false;
    }
  }

  bool canRespondBlockChallenge(CoupRoomModel room) {
    final action = room.currentAction;
    if (room.phase != GamePhase.blockChallenge || action == null) return false;
    if (!isMeAlive) return false;
    return action.blockerId != userName;
  }

  String displayNameOf(String? playerId) {
    if (playerId == null || playerId.isEmpty) return '...';
    final player = currentRoom.value?.players.firstWhereOrNull((p) => p.name == playerId);
    return player?.shownName ?? playerId;
  }

  @override
  void onInit() {
    super.onInit();

    // Accept both Get.arguments and URL query parameters to avoid null-cast crashes.
    final dynamic args = Get.arguments;
    if (args is Map) {
      final roomFromArgs = args['roomCode'];
      final userFromArgs = args['userName'];
      if (roomFromArgs is String && roomFromArgs.isNotEmpty) {
        roomCode = roomFromArgs;
      }
      if (userFromArgs is String && userFromArgs.isNotEmpty) {
        userName = userFromArgs;
      }
    }

    roomCode = roomCode.isNotEmpty ? roomCode : (Get.parameters['roomCode'] ?? '');
    userName = userName.isNotEmpty ? userName : (Get.parameters['userName'] ?? '');
  }

  @override
  void onReady() {
    super.onReady();
    if (roomCode.isEmpty || userName.isEmpty) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    _subscribeRoom();
    _subscribeHistory();
  }

  @override
  void onClose() {
    _cancelAutoDecision();
    _roomStreamSubscription?.cancel();
    _historyStreamSubscription?.cancel();
    super.onClose();
  }

  void _cancelAutoDecision() {
    _autoDecisionTimer?.cancel();
    _countdownTicker?.cancel();
    autoActionCountdown.value = 0;
  }

  void setAutoActionEnabled(bool enabled) {
    autoActionEnabled.value = enabled;
    if (!enabled) {
      _cancelAutoDecision();
      return;
    }

    final room = currentRoom.value;
    if (room != null) {
      _scheduleAutoDecision(room);
    }
  }

  void _scheduleAutoDecision(CoupRoomModel room) {
    _cancelAutoDecision();
    if (!autoActionEnabled.value) return;

    var shouldAuto = false;
    if (room.phase == GamePhase.action) {
      shouldAuto = canAct;
    } else if (room.phase == GamePhase.challenge) {
      shouldAuto = canRespondChallenge(room);
    } else if (room.phase == GamePhase.block) {
      shouldAuto = canRespondBlock(room);
    } else if (room.phase == GamePhase.blockChallenge) {
      shouldAuto = canRespondBlockChallenge(room);
    }

    if (!shouldAuto) return;

    autoActionCountdown.value = 2;
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = autoActionCountdown.value - 1;
      autoActionCountdown.value = next < 0 ? 0 : next;
      if (autoActionCountdown.value == 0) {
        timer.cancel();
      }
    });

    _autoDecisionTimer = Timer(const Duration(seconds: 5), () async {
      final latest = currentRoom.value;
      if (latest == null) return;

      try {
        if (latest.phase == GamePhase.action && canAct) {
          await performAction(CoupActionType.income);
        } else if (latest.phase == GamePhase.challenge && canRespondChallenge(latest)) {
          await passChallenge();
        } else if (latest.phase == GamePhase.block && canRespondBlock(latest)) {
          await passBlockOpportunity(auto: true);
        } else if (latest.phase == GamePhase.blockChallenge && canRespondBlockChallenge(latest)) {
          await passBlockChallenge();
        }
      } catch (_) {
        // ignore auto decision errors; room stream will drive the next state
      }
    });
  }

  void _subscribeHistory() {
    _historyStreamSubscription = _firestoreService.getActionHistoryStream(roomCode).listen((items) {
      historyEntries.assignAll(items);
    });
  }

  void _subscribeRoom() {
    EasyLoading.show(status: 'msgLoadingGame'.tr);
    _roomStreamSubscription = _firestoreService.getRoomStream(roomCode).listen((room) async {
      currentRoom.value = room;
      mePlayer.value = room.players.firstWhereOrNull((element) => element.name == userName);
      _scheduleAutoDecision(room);

      EasyLoading.dismiss();

      if (room.roomState == GameState.waiting) {
        Get.offNamed(
          AppRoutes.lobbyRoom,
          parameters: {
            'roomCode': roomCode,
            'userName': userName,
            'autoReady': '1',
          },
        );
        return;
      }

      if (room.roomState == GameState.finished && room.winnerId != null) {
        EasyLoading.showInfo('msgWinner'.trParams({'name': room.winnerId!}));
      }

      await _processBots(room);
    });
  }

  Future<void> _processBots(CoupRoomModel room) async {
    // Only the host client processes bots to prevent race conditions
    if (room.hostId != userName) return;
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
      EasyLoading.showInfo('gameNotYourTurn'.tr);
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

  Future<void> passBlockOpportunity({bool auto = false}) async {
    String? revealedInfluence;
    final room = currentRoom.value;
    final action = room?.currentAction;
    final isAssassinateTarget = action != null &&
        action.actionType == CoupActionType.assassin &&
        action.target?.name == userName;

    if (isAssassinateTarget) {
      if (auto) {
        final me = mePlayer.value;
        final hiddenCards =
            (me?.cards.where((card) => !card.isRevealed).toList(growable: false) ?? const []);
        if (hiddenCards.isNotEmpty) {
          revealedInfluence = hiddenCards.first.roleType.firestoreValue;
        }
      } else {
        revealedInfluence = await _selectInfluenceToReveal();
        if (revealedInfluence == null) {
          return;
        }
      }
    }

    await _firestoreService.respondToBlockOpportunity(
      roomCode,
      userName,
      block: false,
      revealedInfluence: revealedInfluence,
    );
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

    final options = room.players
        .where((player) => player.name != userName && player.isAlive)
        .map(
          (player) => ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline, color: Color(0xFFEDD97A), size: 18),
            title: Text(
              player.shownName,
              style: const TextStyle(color: Color(0xFFE8EDF5), fontWeight: FontWeight.w600),
            ),
            onTap: () => Get.back(result: player),
          ),
        )
        .toList(growable: false);

    return _showStyledChoiceDialog<CoupPlayerModel>('gameSelectTarget'.tr, options);
  }

  Future<String?> _selectInfluenceToReveal() async {
    final me = mePlayer.value;
    if (me == null) return null;

    final hiddenCards = me.cards.where((card) => !card.isRevealed).toList(growable: false);
    if (hiddenCards.isEmpty) return null;
    if (hiddenCards.length == 1) return hiddenCards.first.roleType.firestoreValue;

    final options = hiddenCards
        .map(
          (card) => ListTile(
            dense: true,
            leading: Icon(card.roleType.icon, color: const Color(0xFFEDD97A), size: 18),
            title: Text(
              card.roleType.firestoreValue.toUpperCase(),
              style: const TextStyle(color: Color(0xFFE8EDF5), fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'gameRevealThisCard'.tr,
              style: const TextStyle(color: Color(0xFF7A8CA8), fontSize: 12),
            ),
            onTap: () => Get.back(result: card.roleType.firestoreValue),
          ),
        )
        .toList(growable: false);

    return _showStyledChoiceDialog<String>('gameSelectInfluenceToReveal'.tr, options);
  }

  Future<T?> _showStyledChoiceDialog<T>(String title, List<Widget> options) {
    return Get.dialog<T>(
      Dialog(
        backgroundColor: const Color(0xFF18243E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A3A5E)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFEDD97A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
