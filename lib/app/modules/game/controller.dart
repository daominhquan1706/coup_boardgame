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
  set text(text) => _text.value = text;
  get text => _text.value;

  //get firebase service
  FirestoreService get _firestoreService => Get.find<FirestoreService>();

  late StreamSubscription? _roomStreamSubscription;

  final Rx<CoupRoomModel?> currentRoom = Rx<CoupRoomModel?>(null);
  late Rx<CoupPlayerModel?> mePlayer = Rx<CoupPlayerModel?>(null);

  late String roomCode;
  late String userName;

  CoupPlayerModel? get currentPlayerTurn {
    final playersAliveInRoom =
        currentRoom.value!.players.where((player) => player.isAlive).toList();

    return playersAliveInRoom
        .firstWhereOrNull((element) => element.name == currentRoom.value!.currentTurn);
  }

  GamePlayingState get gamePlayingState {
    if (currentRoom.value == null) {
      return GamePlayingState.waitingGameStart;
    }

    final player = mePlayer.value;
    final currentAction = currentRoom.value?.currentAction;
    final currentPlayerTurn = currentRoom.value?.currentPlayerTurn;
    
    if (player == currentPlayerTurn) {
      if (currentAction == null) {
        return GamePlayingState.myTurnChooseAction;
      }

      switch (currentAction.actionType) {
          case CoupActionType.duke:
            if (gamePlayingState == GamePlayingState.myTurnWaitingVote) {
              if (currentRoom.value!.isFullyVoted) {
                // Get 3 coins
                mePlayer.value!.coins += 3;
                // Update player's coins in Firestore
                _firestoreService.updatePlayerCoins(roomCode, mePlayer.value!);
              } else if (currentRoom.value!.isChallenged) {
                if (currentRoom.value!.isChallengerDuke) {
                  // Duke gets 3 coins
                  currentPlayerTurn!.coins += 3;
                  // Challenger loses 1 influence
                  currentRoom.value!.challenger!.influence -= 1;
                  // Update player's coins and influence in Firestore
                  _firestoreService.updatePlayerCoins(roomCode, currentPlayerTurn!);
                  _firestoreService.updatePlayerInfluence(roomCode, currentRoom.value!.challenger!);
                } else {
                  // Lose 1 influence
                  mePlayer.value!.influence -= 1;
                  // Update player's influence in Firestore
                  _firestoreService.updatePlayerInfluence(roomCode, mePlayer.value!);
                }
              }
            }
            break;
        
          
          break;
        default:
      }
      
    }
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

  // get room info
  Future<void> getRoomInfo(String roomId) async {
    EasyLoading.show(status: 'Starting...');
    final room = await _firestoreService.getRoom(roomId);
    mePlayer.value = room.players.firstWhere((element) => element.name == userName);

    EasyLoading.dismiss();
    _roomStreamSubscription = _firestoreService.getRoomStream(roomCode).listen((value) {
      currentRoom.value = value;
      mePlayer.value = value.players.firstWhere((element) => element.name == userName);

      switch (value.roomState) {
        case GameState.waiting:
          // Back to lobby if room is waiting
          Get.offNamed(
            AppRoutes.lobbyRoom,
            parameters: {
              'roomCode': roomCode,
              'userName': userName,
            },
          );
          return;
        case GameState.playing:
          break;
        default:
      }
    });
  }

  //end game
  Future<void> endGame() async {
    await _firestoreService.endGame(roomCode);
  }

  Future<void> performAction(CoupActionType action) async {
    final isNeedTarget = CoupFunction.isNeedPlayerTarget(action);
    CoupPlayerModel? targetPlayer;
    if (isNeedTarget) {
      targetPlayer = await _buildDialogTargetPlayer(action);
    }

    final player = mePlayer.value;
    if (player != null) {
      final actionModel = CoupActionModel(
        source: player,
        target: targetPlayer,
        actionType: action,
      );
      _firestoreService.performAction(roomCode, actionModel);
    }
  }

  Future<CoupPlayerModel?> _buildDialogTargetPlayer(CoupActionType action) async {
    return await Get.dialog<CoupPlayerModel?>(
      AlertDialog(
        title: const Text('Select Target Player'),
        content: Column(
          children: currentRoom.value!.players
              .where((player) => player != mePlayer.value)
              .map(
                (player) => ListTile(
                  title: Text(player.name),
                  onTap: () {
                    final actionModel = CoupActionModel(
                      source: mePlayer.value!,
                      actionType: action,
                      target: player,
                    );
                    _firestoreService.performAction(roomCode, actionModel);
                    Get.back();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
