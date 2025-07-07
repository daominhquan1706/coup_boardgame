import 'dart:async';

import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../data/provider/game_provider.dart';

//list roles: Ambasador, Captain, Contessa, Duke, Assassin

// choose Duke action > waiting for vote > fully vote yes > get 3 coins > done
// choose Duke action > waiting for vote > challenged > have Duke > Duke get 3 coins > challenger lose 1 influence > done
// choose Duke action > waiting for vote > challenged > don't have Duke > lose 1 influence > done

// choose Captain action > waiting for vote > fully vote yes > get 2 coins > done
// choose Captain action > waiting for vote > challenged > have Captain > me get 2 coins > challenger lose 1 influence > done
// choose Captain action > waiting for vote > challenged > don't have Captain > lose 1 influence > done
// choose Captain action > waiting for vote > blocked by Captain/Ambasador/Inquisitor > say believe > done
// choose Captain action > waiting for vote > blocked by Captain/Ambasador/Inquisitor > say don't believe > blocker have Captain/Ambasador/Inquisitor > blocker exchange the Captain/Ambasador/Inquisitor from counter > lose 1 influence
// choose Captain action > waiting for vote > blocked by Captain/Ambasador/Inquisitor > say don't believe > blocker don't have Captain/Ambasador/Inquisitor > blocker lose 1 influence > me get 2 coins > done

// choose Ambasador action > waiting for vote > fully vote yes > get 2 cards > return 2 cards > done
// choose Ambasador action > waiting for vote > challenged > have Ambasador > Ambasador get 2 cards > challenger lose 1 influence > done
// choose Ambasador action > waiting for vote > challenged > don't have Ambasador >

// choose Assassin action > choose target > waiting for vote > fully vote yes >  target choose to lose 1 influence > target lose 1 influence > done
// choose Assassin action > choose target > waiting for vote > challenged > have Assassin > me choose to lose 1 influence > challenger lose 1 influence > done
// choose Assassin action > choose target > waiting for vote > challenged > don't have Assassin > lose 1 influence > done
// choose Assassin action > choose target > waiting for vote > blocked by Contessa > say believe > done
// choose Assassin action > choose target > waiting for vote > blocked by Contessa > say don't believe > target have Contessa > target lose 1 influence > done
// choose Assassin action > choose target > waiting for vote > blocked by Contessa > say don't believe > target don't have Contessa > target lose 2 influence > done

enum GamePlayingState {
  waitingGameStart,
  myTurnChooseAction,
  myTurnWaitingVote,
  myTurnFullyVotedChooseCardToExchange,
  myTurnFullyVotedChooseTarget,
  myTurnFullyVotedChooseCardToReturn,
  myTurnFullyVotedChooseTargetToLoseInfluence,
  myTurnFullyVotedChooseTargetToGetCoins,
  myTurnFullyVotedChooseTargetToExchangeCard,
  myTurnFullyVotedChooseTargetToBlock,
  myTurnFullyVotedChooseTargetToChallenge,
  myTurnFullyVotedChooseTargetToBelieve,
  myTurnFullyVotedChooseTargetToDontBelieve,
  myTurnFullyVotedChooseTargetToLoseInfluenceByBlocker,
  myTurnFullyVotedChooseTargetToGetCoinsByBlocker,
  myTurnFullyVotedChooseTargetToExchangeCardByBlocker,
  myTurnFullyVotedChooseTargetToLoseInfluenceByChallenger,
  myTurnFullyVotedChooseTargetToGetCoinsByChallenger,
  myTurnFullyVotedChooseTargetToExchangeCardByChallenger,
  myTurnFullyVotedChooseTargetToLoseInfluenceByTarget,
  myTurnFullyVotedChooseTargetToGetCoinsByTarget,
  myTurnFullyVotedChooseTargetToExchangeCardByTarget,
  myTurnFullyVotedChooseTargetToLoseInfluenceByTargetByBlocker,
  myTurnFullyVotedChooseTargetToGetCoinsByTargetByBlocker,
  myTurnFullyVotedChooseTargetToExchangeCardByTargetByBlocker,
  myTurnFullyVotedChooseTargetToLoseInfluenceByTargetByChallenger,
  myTurnFullyVotedChooseTargetToGetCoinsByTargetByChallenger,
  myTurnFullyVotedChooseTargetToExchangeCardByTargetByChallenger,
  myTurnFullyVotedChooseTargetToLoseInfluenceByTargetByChallengerByBlocker,
  myTurnFullyVotedChooseTargetToGetCoinsByTargetByChallengerByBlocker,
  myTurnFullyVotedChooseTargetToExchangeCardByTargetByChallengerByBlocker,
  myTurnFullyVotedChooseTargetToLoseInfluenceByTargetByChallengerByBlockerByChallenger,
  myTurnFullyVotedChooseTargetToGetCoinsByTargetByChallengerByBlockerByChall
}

class GameStartController extends GetxController {
  final GameProvider? provider;
  GameStartController({this.provider});

  final _text = 'GameStart'.obs;
  final _currentRoom = Rx<CoupRoomModel?>(null);
  final _mePlayer = Rx<CoupPlayerModel?>(null);
  final _isLoading = false.obs;

  String get text => _text.value;
  CoupRoomModel? get currentRoom => _currentRoom.value;
  CoupPlayerModel? get mePlayer => _mePlayer.value;
  bool get isLoading => _isLoading.value;

  Timer? _updateTimer;
  StreamSubscription? _roomStreamSubscription;

  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  late String roomCode;
  late String userName;

  CoupPlayerModel? get currentPlayerTurn {
    final room = _currentRoom.value;
    if (room == null) return null;
    
    final playersAliveInRoom = room.players.where((player) => player.isAlive).toList();
    return playersAliveInRoom.firstWhereOrNull(
      (element) => element.name == room.currentTurn,
    );
  }

  GamePlayingState get gamePlayingState {
    final room = _currentRoom.value;
    if (room == null) return GamePlayingState.waitingGameStart;

    final player = _mePlayer.value;
    final currentAction = room.currentAction;
    final currentPlayerTurn = currentPlayerTurn;
    
    if (player == currentPlayerTurn) {
      if (currentAction == null) {
        return GamePlayingState.myTurnChooseAction;
      }

      switch (currentAction.actionType) {
          case CoupActionType.duke:
            if (gamePlayingState == GamePlayingState.myTurnWaitingVote) {
              if (room.isFullyVoted) {
                // Get 3 coins
                _mePlayer.value!.coins += 3;
                // Update player's coins in Firestore
                _firestoreService.updatePlayerCoins(roomCode, _mePlayer.value!);
              } else if (room.isChallenged) {
                if (room.isChallengerDuke) {
                  // Duke gets 3 coins
                  currentPlayerTurn!.coins += 3;
                  // Challenger loses 1 influence
                  room.challenger!.influence -= 1;
                  // Update player's coins and influence in Firestore
                  _firestoreService.updatePlayerCoins(roomCode, currentPlayerTurn!);
                  _firestoreService.updatePlayerInfluence(roomCode, room.challenger!);
                } else {
                  // Lose 1 influence
                  _mePlayer.value!.influence -= 1;
                  // Update player's influence in Firestore
                  _firestoreService.updatePlayerInfluence(roomCode, _mePlayer.value!);
                }
              }
            }
            break;
        
          
          break;
        default:
      }
      
    }
    
    return GamePlayingState.waitingGameStart;
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
    _roomStreamSubscription?.cancel();
    _updateTimer?.cancel();
    super.onClose();
  }

  Future<void> getRoomInfo(String roomId) async {
    try {
      _isLoading.value = true;
      EasyLoading.show(status: 'Starting...');
      
      final room = await _firestoreService.getRoom(roomId);
      final player = room.players.firstWhereOrNull(
        (element) => element.name == userName,
      );
      
      if (player == null) {
        EasyLoading.dismiss();
        Get.offAllNamed(AppRoutes.home);
        return;
      }
      
      _mePlayer.value = player;
      _currentRoom.value = room;
      
      EasyLoading.dismiss();
      _isLoading.value = false;
      
      _roomStreamSubscription = _firestoreService
          .getRoomStream(roomCode)
          .listen(_onRoomUpdate);
          
    } catch (e) {
      EasyLoading.dismiss();
      _isLoading.value = false;
      Get.snackbar('Error', 'Failed to load game: $e');
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void _onRoomUpdate(CoupRoomModel room) {
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 100), () {
      _currentRoom.value = room;
      
      final updatedPlayer = room.players.firstWhereOrNull(
        (element) => element.name == userName,
      );
      
      if (updatedPlayer != null) {
        _mePlayer.value = updatedPlayer;
      }

      switch (room.roomState) {
        case GameState.waiting:
          Get.offNamed(
            AppRoutes.lobbyRoom,
            parameters: {
              'roomCode': roomCode,
              'userName': userName,
            },
          );
          break;
        case GameState.playing:
          update(['players', 'gameState', 'actions']);
          break;
        default:
          break;
      }
    });
  }

  Future<void> endGame() async {
    try {
      _isLoading.value = true;
      EasyLoading.show(status: 'Ending game...');
      
      await _firestoreService.endGame(roomCode);
      
      EasyLoading.dismiss();
      _isLoading.value = false;
    } catch (e) {
      EasyLoading.dismiss();
      _isLoading.value = false;
      Get.snackbar('Error', 'Failed to end game: $e');
    }
  }

  Future<void> performAction(CoupActionType action) async {
    try {
      final player = _mePlayer.value;
      if (player == null) return;

      _isLoading.value = true;
      
      final isNeedTarget = CoupFunction.isNeedPlayerTarget(action);
      CoupPlayerModel? targetPlayer;
      
      if (isNeedTarget) {
        targetPlayer = await _buildDialogTargetPlayer(action);
        if (targetPlayer == null) {
          _isLoading.value = false;
          return; // User cancelled
        }
      }

      final actionModel = CoupActionModel(
        source: player,
        target: targetPlayer,
        actionType: action,
      );
      
      await _firestoreService.performAction(roomCode, actionModel);
      
      _isLoading.value = false;
      
      update(['actions', 'gameState']);
      
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar('Error', 'Failed to perform action: $e');
    }
  }

  Future<CoupPlayerModel?> _buildDialogTargetPlayer(CoupActionType action) async {
    final room = _currentRoom.value;
    if (room == null) return null;
    
    final availablePlayers = room.players
        .where((player) => player != _mePlayer.value && player.isAlive)
        .toList();
    
    if (availablePlayers.isEmpty) return null;
    
    return await Get.dialog<CoupPlayerModel?>(
      AlertDialog(
        title: Text('Select Target Player for ${action.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availablePlayers
                .map(
                  (player) => ListTile(
                    title: Text(player.name),
                    subtitle: Text('Coins: ${player.coins}'),
                    leading: CircleAvatar(
                      child: Text(player.name.substring(0, 1).toUpperCase()),
                    ),
                    onTap: () => Get.back(result: player),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  bool get isMyTurn => currentPlayerTurn?.name == userName;
  bool get canPerformAction => isMyTurn && !isLoading;
  
  List<CoupPlayerModel> get alivePlayers =>
      _currentRoom.value?.players.where((p) => p.isAlive).toList() ?? [];
  
  List<CoupPlayerModel> get otherPlayers =>
      alivePlayers.where((p) => p.name != userName).toList();

  void updatePlayers() => update(['players']);
  void updateGameState() => update(['gameState']);
  void updateActions() => update(['actions']);
}
