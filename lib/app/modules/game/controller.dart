import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/game_history_entry.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/modules/game/widgets/card_widget.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/constants/local_storage_keys.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:coup_boardgame/app/utils/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/provider/game_provider.dart';

class GameStartController extends GetxController {
  final GameProvider? provider;
  GameStartController({this.provider});

  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final GetStorage _storage = GetStorage();

  final Rx<CoupRoomModel?> currentRoom = Rx<CoupRoomModel?>(null);
  final Rx<CoupPlayerModel?> mePlayer = Rx<CoupPlayerModel?>(null);
  final RxList<GameHistoryEntry> historyEntries = <GameHistoryEntry>[].obs;
  final RxInt autoActionCountdown = 0.obs;
  final RxBool autoActionEnabled = false.obs;

  StreamSubscription<CoupRoomModel>? _roomStreamSubscription;
  StreamSubscription<List<GameHistoryEntry>>? _historyStreamSubscription;
  Timer? _autoDecisionTimer;
  Timer? _countdownTicker;
  bool _isExchangeSelectionDialogOpen = false;
  String? _handledExchangeSelectionActionId;
  bool _isRevealSelectionDialogOpen = false;
  String? _handledRevealSelectionActionId;

  String roomCode = '';
  String userName = '';

  bool _isProcessingBots = false;

  CoupPlayerModel? get currentPlayerTurn {
    final room = currentRoom.value;
    if (room == null) return null;
    return room.players
        .firstWhereOrNull((element) => element.name == room.currentTurn);
  }

  bool get isMyTurn {
    final turnOwner = currentRoom.value?.currentTurn;
    if (turnOwner == null || turnOwner.isEmpty) return false;

    final me = mePlayer.value;
    return turnOwner == userName ||
        turnOwner == me?.name ||
        turnOwner == me?.shownName;
  }

  bool get canAct {
    final room = currentRoom.value;
    if (room == null) return false;
    return room.roomState == GameState.playing &&
        room.phase == GamePhase.action &&
        isMyTurn;
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
      case CoupActionType.coup:
      case CoupActionType.assassin:
      case CoupActionType.captain:
        return action.target?.name == userName;
      default:
        return false;
    }
  }

  bool _requiresManualRevealSelectionInBlock(CoupRoomModel room) {
    final action = room.currentAction;
    if (room.phase != GamePhase.block || action == null) return false;
    final isRevealAction = action.actionType == CoupActionType.coup ||
        action.actionType == CoupActionType.assassin;
    return isRevealAction && action.target?.name == userName;
  }

  bool canRespondBlockChallenge(CoupRoomModel room) {
    final action = room.currentAction;
    if (room.phase != GamePhase.blockChallenge || action == null) return false;
    if (!isMeAlive) return false;
    return action.blockerId != userName;
  }

  String displayNameOf(String? playerId) {
    if (playerId == null || playerId.isEmpty) return '...';
    final player =
        currentRoom.value?.players.firstWhereOrNull((p) => p.name == playerId);
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

    roomCode =
        roomCode.isNotEmpty
            ? roomCode
            : (Get.parameters['room_code'] ?? Get.parameters['roomCode'] ?? '');
    userName =
        userName.isNotEmpty
            ? userName
            : (_storage.read<String>(LocalStorageKeys.userName) ??
                Get.parameters['userName'] ??
                '');
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
      shouldAuto =
          canRespondBlock(room) && !_requiresManualRevealSelectionInBlock(room);
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
        } else if (latest.phase == GamePhase.challenge &&
            canRespondChallenge(latest)) {
          await passChallenge();
        } else if (latest.phase == GamePhase.block &&
            canRespondBlock(latest) &&
            !_requiresManualRevealSelectionInBlock(latest)) {
          await passBlockOpportunity(auto: true);
        } else if (latest.phase == GamePhase.blockChallenge &&
            canRespondBlockChallenge(latest)) {
          await passBlockChallenge();
        }
      } catch (_) {
        // ignore auto decision errors; room stream will drive the next state
      }
    });
  }

  void _subscribeHistory() {
    _historyStreamSubscription =
        _firestoreService.getActionHistoryStream(roomCode).listen((items) {
      historyEntries.assignAll(items);
    });
  }

  void _subscribeRoom() {
    AppToast.info('msgLoadingGame'.tr,
        duration: const Duration(milliseconds: 900));
    _roomStreamSubscription =
        _firestoreService.getRoomStream(roomCode).listen((room) async {
      currentRoom.value = room;
      mePlayer.value =
          room.players.firstWhereOrNull((element) => element.name == userName);
      _scheduleAutoDecision(room);
      _maybeHandlePendingRevealSelection(room);
      _maybeHandlePendingExchangeSelection(room);

      if (room.roomState == GameState.waiting) {
        Get.offNamed(
          AppRoutes.lobbyRoomPath(roomCode),
          parameters: {
            'autoReady': '1',
          },
        );
        return;
      }

      if (room.roomState == GameState.finished && room.winnerId != null) {
        AppToast.success('msgWinner'.trParams({'name': room.winnerId!}));
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
      AppToast.info('gameNotYourTurn'.tr);
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
      await _firestoreService.performAction(
        roomCode,
        actionModel,
      );
    } catch (e) {
      AppToast.error(e.toString());
    }
  }

  Future<void> passChallenge() async {
    await _firestoreService.respondToChallenge(roomCode, userName,
        challenge: false);
  }

  Future<void> challengeAction() async {
    await _firestoreService.respondToChallenge(roomCode, userName,
        challenge: true);
  }

  Future<void> passBlockOpportunity({bool auto = false}) async {
    String? revealedInfluence;
    final room = currentRoom.value;
    final action = room?.currentAction;
    final isRevealTarget = action != null &&
        (action.actionType == CoupActionType.assassin ||
            action.actionType == CoupActionType.coup) &&
        action.target?.name == userName;

    if (auto && isRevealTarget) return;

    if (isRevealTarget) {
      revealedInfluence = await _selectInfluenceToReveal();
      if (revealedInfluence == null) {
        return;
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
    await _firestoreService.respondToBlockChallenge(roomCode, userName,
        challenge: false);
  }

  Future<void> challengeBlock() async {
    await _firestoreService.respondToBlockChallenge(roomCode, userName,
        challenge: true);
  }

  Future<CoupPlayerModel?> _buildDialogTargetPlayer() async {
    final room = currentRoom.value;
    if (room == null) return null;

    final options = room.players
        .where((player) => player.name != userName && player.isAlive)
        .map(
          (player) => ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline,
                color: Color(0xFFEDD97A), size: 18),
            title: Text(
              player.shownName,
              style: const TextStyle(
                  color: Color(0xFFE8EDF5), fontWeight: FontWeight.w600),
            ),
            onTap: () => Get.back(result: player),
          ),
        )
        .toList(growable: false);

    return _showStyledChoiceDialog<CoupPlayerModel>(
        'gameSelectTarget'.tr, options);
  }

  Future<String?> _selectInfluenceToReveal() async {
    final me = mePlayer.value;
    if (me == null) return null;

    final hiddenCards =
        me.cards.where((card) => !card.isRevealed).toList(growable: false);
    if (hiddenCards.isEmpty) return null;

    final revealCandidates = hiddenCards
        .asMap()
        .entries
        .map(
          (entry) => _ExchangeCandidate(
            id: 'reveal_${entry.key}',
            roleType: entry.value.roleType,
            isFromDraw: false,
            sourceLabel: 'gameRevealThisCard'.tr,
          ),
        )
        .toList(growable: false);

    return _showRevealSelectionDialog(revealCandidates);
  }

  Future<String?> _showRevealSelectionDialog(
    List<_ExchangeCandidate> candidates,
  ) {
    return Get.dialog<String>(
      Dialog(
        backgroundColor: const Color(0xFF18243E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A3A5E)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'gameSelectInfluenceToReveal'.tr,
                  style: const TextStyle(
                    color: Color(0xFFEDD97A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: candidates.map((candidate) {
                    return _buildExchangeCandidateCard(
                      candidate: candidate,
                      selected: false,
                      onTap: () =>
                          Get.back(result: candidate.roleType.firestoreValue),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _maybeHandlePendingRevealSelection(CoupRoomModel room) {
    final action = room.currentAction;
    final isPendingReveal = room.phase == GamePhase.resolve &&
        action != null &&
        action.status == 'awaiting_reveal_selection';

    if (!isPendingReveal) {
      _handledRevealSelectionActionId = null;
      return;
    }

    if (action.revealChooserId != userName) {
      return;
    }

    final actionId = action.actionId;
    if (actionId == null) {
      return;
    }

    if (_isRevealSelectionDialogOpen ||
        _handledRevealSelectionActionId == actionId) {
      return;
    }

    _handledRevealSelectionActionId = actionId;
    _isRevealSelectionDialogOpen = true;

    Future<void>(() async {
      try {
        final revealedInfluence = await _selectInfluenceToReveal();
        if (revealedInfluence == null) {
          _handledRevealSelectionActionId = null;
          final latest = currentRoom.value;
          if (latest != null) {
            Future<void>(() => _maybeHandlePendingRevealSelection(latest));
          }
          return;
        }

        await _firestoreService.submitRevealSelection(
          roomCode,
          userName,
          revealedInfluence: revealedInfluence,
        );
      } catch (e) {
        AppToast.error(e.toString());
        _handledRevealSelectionActionId = null;
      } finally {
        _isRevealSelectionDialogOpen = false;
      }
    });
  }

  void _maybeHandlePendingExchangeSelection(CoupRoomModel room) {
    final action = room.currentAction;
    final isPendingExchange = room.phase == GamePhase.resolve &&
        action != null &&
        action.actionType == CoupActionType.ambassador &&
        action.status == 'awaiting_exchange_selection';

    if (!isPendingExchange) {
      _handledExchangeSelectionActionId = null;
      return;
    }

    if (action.source.name != userName) {
      return;
    }

    final actionId = action.actionId;
    if (actionId == null) {
      return;
    }

    if (_isExchangeSelectionDialogOpen ||
        _handledExchangeSelectionActionId == actionId) {
      return;
    }

    _handledExchangeSelectionActionId = actionId;
    _isExchangeSelectionDialogOpen = true;

    Future<void>(() async {
      try {
        final keepInfluences =
            await _selectInfluencesToKeepForPendingExchange(action);
        if (keepInfluences == null) {
          _handledExchangeSelectionActionId = null;
          final latest = currentRoom.value;
          if (latest != null) {
            Future<void>(() => _maybeHandlePendingExchangeSelection(latest));
          }
          return;
        }

        await _firestoreService.submitExchangeSelection(
          roomCode,
          userName,
          keepInfluences: keepInfluences,
        );
      } catch (e) {
        AppToast.error(e.toString());
        _handledExchangeSelectionActionId = null;
      } finally {
        _isExchangeSelectionDialogOpen = false;
      }
    });
  }

  Future<List<String>?> _selectInfluencesToKeepForPendingExchange(
    CoupActionModel action,
  ) async {
    final pool = action.exchangePool ?? const <String>[];
    final originalHidden = action.exchangeOriginalHidden ?? const <String>[];
    final hiddenToKeep = action.exchangeHiddenToKeep ?? 0;

    if (hiddenToKeep <= 0) {
      return const <String>[];
    }

    if (pool.isEmpty) {
      return null;
    }

    final currentCountByRole = <String, int>{};
    for (final role in originalHidden) {
      currentCountByRole[role] = (currentCountByRole[role] ?? 0) + 1;
    }

    final candidates = <_ExchangeCandidate>[];
    final defaultSelectedIds = <String>{};
    for (var i = 0; i < pool.length; i++) {
      final firestoreValue = pool[i];
      final roleType = CoupRoleTypeX.tryFromFirestoreValue(firestoreValue);
      if (roleType == null) continue;

      final availableCurrent = currentCountByRole[firestoreValue] ?? 0;
      final isCurrentCard = availableCurrent > 0;
      if (isCurrentCard) {
        currentCountByRole[firestoreValue] = availableCurrent - 1;
      }

      final candidate = _ExchangeCandidate(
        id: 'pool_$i',
        roleType: roleType,
        isFromDraw: !isCurrentCard,
        sourceLabel: isCurrentCard
            ? 'gameSwapSourceCurrent'.tr
            : 'gameSwapSourceDraw'.tr,
      );
      candidates.add(candidate);
      if (isCurrentCard && defaultSelectedIds.length < hiddenToKeep) {
        defaultSelectedIds.add(candidate.id);
      }
    }

    if (candidates.length <= hiddenToKeep) {
      return candidates
          .map((candidate) => candidate.roleType.firestoreValue)
          .toList(growable: false);
    }

    return _showExchangeSelectionDialog(
      candidates: candidates,
      hiddenToKeep: hiddenToKeep,
      initialSelectedIds: defaultSelectedIds,
    );
  }

  Future<List<String>?> _showExchangeSelectionDialog({
    required List<_ExchangeCandidate> candidates,
    required int hiddenToKeep,
    Set<String>? initialSelectedIds,
  }) {
    final selectedIds = <String>{...(initialSelectedIds ?? const <String>{})};
    final currentCards = candidates
        .where((candidate) => !candidate.isFromDraw)
        .toList(growable: false);
    final drawnCards = candidates
        .where((candidate) => candidate.isFromDraw)
        .toList(growable: false);

    return Get.dialog<List<String>>(
      StatefulBuilder(
        builder: (context, setState) {
          void toggleCandidate(_ExchangeCandidate candidate) {
            if (selectedIds.contains(candidate.id)) {
              setState(() {
                selectedIds.remove(candidate.id);
              });
              return;
            }

            if (selectedIds.length >= hiddenToKeep) {
              setState(() {
                // Replace the oldest picked card with the newly tapped card.
                selectedIds.remove(selectedIds.first);
                selectedIds.add(candidate.id);
              });
              return;
            }

            setState(() {
              selectedIds.add(candidate.id);
            });
          }

          return Dialog(
            backgroundColor: const Color(0xFF18243E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF2A3A5E)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'gameSelectSwapKeepTitle'.tr,
                      style: const TextStyle(
                        color: Color(0xFFEDD97A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'gameSelectSwapKeepHint'
                          .trParams({'count': '$hiddenToKeep'}),
                      style: const TextStyle(
                          color: Color(0xFF7A8CA8), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${selectedIds.length}/$hiddenToKeep',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (currentCards.isNotEmpty)
                              _buildExchangeSection(
                                title: 'gameSwapSectionCurrent'.tr,
                                candidates: currentCards,
                                selectedIds: selectedIds,
                                onToggle: toggleCandidate,
                              ),
                            if (drawnCards.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildExchangeSection(
                                title: 'gameSwapSectionDrawn'.tr,
                                candidates: drawnCards,
                                selectedIds: selectedIds,
                                onToggle: toggleCandidate,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedIds.length != hiddenToKeep) {
                            AppToast.info(
                              'gameSwapNeedExactSelect'
                                  .trParams({'count': '$hiddenToKeep'}),
                            );
                            return;
                          }

                          final keep = candidates
                              .where((candidate) =>
                                  selectedIds.contains(candidate.id))
                              .map((candidate) =>
                                  candidate.roleType.firestoreValue)
                              .toList(growable: false);
                          Get.back(result: keep);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF0F1728),
                        ),
                        child: Text('commonConfirm'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildExchangeCandidateCard({
    required _ExchangeCandidate candidate,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 92,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF24385D) : const Color(0xFF121D33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFD4AF37) : const Color(0xFF2A3A5E),
            width: selected ? 1.6 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Center(
                  child: CardWidget(
                    roleType: candidate.roleType,
                    small: true,
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              candidate.sourceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9FB3D9),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeSection({
    required String title,
    required List<_ExchangeCandidate> candidates,
    required Set<String> selectedIds,
    required void Function(_ExchangeCandidate) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF9FB3D9),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: candidates.map((candidate) {
            final selected = selectedIds.contains(candidate.id);
            return _buildExchangeCandidateCard(
              candidate: candidate,
              selected: selected,
              onTap: () => onToggle(candidate),
            );
          }).toList(growable: false),
        ),
      ],
    );
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

class _ExchangeCandidate {
  final String id;
  final CoupRoleType roleType;
  final bool isFromDraw;
  final String sourceLabel;

  const _ExchangeCandidate({
    required this.id,
    required this.roleType,
    required this.isFromDraw,
    required this.sourceLabel,
  });
}
