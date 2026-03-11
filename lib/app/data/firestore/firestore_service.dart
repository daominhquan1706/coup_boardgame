import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/utils/constants.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _games => _firestore.collection('games');

  CollectionReference<Map<String, dynamic>> _playersRef(String gameId) {
    return _games.doc(gameId).collection('players');
  }

  CollectionReference<Map<String, dynamic>> _actionsRef(String gameId) {
    return _games.doc(gameId).collection('actions');
  }

  CollectionReference<Map<String, dynamic>> _blocksRef(String gameId) {
    return _games.doc(gameId).collection('blocks');
  }

  CollectionReference<Map<String, dynamic>> _challengesRef(String gameId) {
    return _games.doc(gameId).collection('challenges');
  }

  Future<bool> createRoom(String roomId, List<String> players) async {
    try {
      final hostId = players.isNotEmpty ? players.first : 'host';
      await _games.doc(roomId).set({
        'status': 'waiting',
        'hostId': hostId,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': null,
        'currentTurnPlayerId': null,
        'phase': 'waiting',
        'deck': <String>[],
        'winnerId': null,
        'playerOrder': <String>[],
        'playersCount': 0,
        'currentActionId': null,
        'currentBlockId': null,
      });

      if (players.isNotEmpty) {
        await joinRoom(
          roomId,
          CoupPlayerModel(
            name: players.first,
            isReady: true,
            cards: const <CoupCardModel>[],
            isAlive: true,
            coins: 2,
          ),
        );
      }

      return true;
    } catch (e) {
      Get.log('Failed to create room: $e');
      return false;
    }
  }

  Future<CoupRoomModel> getRoom(String roomId) async {
    final gameDoc = await _games.doc(roomId).get();
    if (!gameDoc.exists || gameDoc.data() == null) {
      throw UnknownError();
    }

    final game = gameDoc.data()!;
    final playersSnap = await _playersRef(roomId).get();
    final players = playersSnap.docs.map((doc) => _playerFromFirestore(doc.id, doc.data())).toList();

    final playerOrder = (game['playerOrder'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    players.sort((a, b) {
      final aIndex = playerOrder.indexOf(a.name);
      final bIndex = playerOrder.indexOf(b.name);
      if (aIndex == -1 && bIndex == -1) return a.name.compareTo(b.name);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });

    final actionId = game['currentActionId'] as String?;
    CoupActionModel? currentAction;
    if (actionId != null) {
      final actionDoc = await _actionsRef(roomId).doc(actionId).get();
      if (actionDoc.exists && actionDoc.data() != null) {
        currentAction = _actionFromFirestore(actionId, actionDoc.data()!, players);
      }
    }

    final deckStrings = (game['deck'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList();

    return CoupRoomModel(
      roomId: roomId,
      players: players,
      roomState: GameStateExtension.fromName((game['status'] as String?) ?? 'waiting'),
      phase: GamePhaseX.fromName((game['phase'] as String?) ?? 'waiting'),
      hostId: game['hostId'] as String?,
      deck: deckStrings
          .map((value) => CoupCardModel(
                roleType: CoupRoleTypeX.fromFirestoreValue(value),
                isRevealed: false,
              ))
          .toList(),
      currentTurn: game['currentTurnPlayerId'] as String?,
      winnerId: game['winnerId'] as String?,
      playerOrder: playerOrder,
      currentAction: currentAction,
    );
  }

  Stream<CoupRoomModel> getRoomStream(String roomId) {
    return _games.doc(roomId).snapshots().asyncMap((_) => getRoom(roomId));
  }

  Future<bool> joinRoom(String roomId, CoupPlayerModel player) async {
    try {
      final gameRef = _games.doc(roomId);
      final playerRef = _playersRef(roomId).doc(player.name);

      await _firestore.runTransaction((tx) async {
        final gameSnap = await tx.get(gameRef);
        if (!gameSnap.exists || gameSnap.data() == null) {
          throw JoinRoomError('Room not found');
        }

        final game = gameSnap.data()!;
        final status = (game['status'] as String?) ?? 'waiting';
        if (status != 'waiting') {
          throw JoinRoomError('Game already started');
        }

        final count = (game['playersCount'] as int?) ?? 0;
        if (count >= Constant.maxPlayersPerRoom) {
          throw JoinRoomError('Room is full');
        }

        final existingPlayer = await tx.get(playerRef);
        if (!existingPlayer.exists) {
          tx.update(gameRef, {
            'playersCount': count + 1,
            'playerOrder': FieldValue.arrayUnion(<String>[player.name]),
          });
        }

        tx.set(playerRef, _playerToFirestore(player), SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      Get.log('Failed to add player to room: $e');
      rethrow;
    }
  }

  Future<void> addBot(String roomId) async {
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    await joinRoom(
      roomId,
      CoupPlayerModel(
        name: 'BOT_$suffix',
        isReady: true,
        cards: const <CoupCardModel>[],
        isAlive: true,
        coins: 2,
        isBot: true,
      ),
    );
  }

  Future<void> removeBot(String roomId) async {
    final gameRef = _games.doc(roomId);
    final botsSnap = await _playersRef(roomId).where('isBot', isEqualTo: true).limit(1).get();
    if (botsSnap.docs.isEmpty) return;

    final botRef = botsSnap.docs.first.reference;

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) return;

      final game = gameSnap.data()!;
      if ((game['status'] as String?) != 'waiting') return;

      final count = (game['playersCount'] as int?) ?? 0;
      tx.delete(botRef);
      tx.update(gameRef, {
        'playersCount': count > 0 ? count - 1 : 0,
        'playerOrder': FieldValue.arrayRemove(<String>[botRef.id]),
      });
    });
  }

  Future<bool> isCanJoinRoom(String roomId, String userName) async {
    final game = await _games.doc(roomId).get();

    if (!game.exists || game.data() == null) {
      throw JoinRoomError('Room not found');
    }

    final status = (game.data()!['status'] as String?) ?? 'waiting';
    if (status != 'waiting') {
      throw JoinRoomError('Game already started');
    }

    final count = (game.data()!['playersCount'] as int?) ?? 0;
    if (count >= Constant.maxPlayersPerRoom) {
      throw JoinRoomError('Room is full');
    }

    final playerDoc = await _playersRef(roomId).doc(userName).get();
    if (playerDoc.exists) {
      throw JoinRoomError('Name is already exist');
    }

    return true;
  }

  Future<CoupPlayerModel> getPlayer(String roomId, String userName) async {
    final playerDoc = await _playersRef(roomId).doc(userName).get();
    if (!playerDoc.exists || playerDoc.data() == null) {
      throw UnknownError();
    }

    return _playerFromFirestore(userName, playerDoc.data()!);
  }

  Future<void> startGame(String roomId) async {
    final gameRef = _games.doc(roomId);
    final playersSnap = await _playersRef(roomId).get();

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) {
        throw UnknownError();
      }

      final game = gameSnap.data()!;
      final status = (game['status'] as String?) ?? 'waiting';
      if (status != 'waiting') {
        return;
      }

      if (playersSnap.docs.length < 2) {
        throw JoinRoomError('Need at least 2 players');
      }

      final playerIds = playersSnap.docs.map((e) => e.id).toList()..shuffle(_random);
      final deck = _generateStandardDeck();

      for (final playerDoc in playersSnap.docs) {
        final first = deck.removeLast();
        final second = deck.removeLast();
        tx.update(playerDoc.reference, {
          'coins': 2,
          'alive': true,
          'influences': <String>[first, second],
          'revealedInfluences': <String>[],
          'isBot': (playerDoc.data()['isBot'] as bool?) ?? false,
        });
      }

      tx.update(gameRef, {
        'status': 'playing',
        'phase': 'action',
        'startedAt': FieldValue.serverTimestamp(),
        'deck': deck,
        'playerOrder': playerIds,
        'currentTurnPlayerId': playerIds.first,
        'winnerId': null,
        'currentActionId': null,
        'currentBlockId': null,
      });
    });
  }

  Future<void> endGame(String roomId) async {
    final gameRef = _games.doc(roomId);
    final players = await _playersRef(roomId).get();

    await _firestore.runTransaction((tx) async {
      for (final player in players.docs) {
        tx.update(player.reference, {
          'coins': 2,
          'alive': true,
          'influences': <String>[],
          'revealedInfluences': <String>[],
        });
      }

      tx.update(gameRef, {
        'status': 'waiting',
        'phase': 'waiting',
        'currentTurnPlayerId': null,
        'winnerId': null,
        'deck': <String>[],
        'playerOrder': <String>[],
        'currentActionId': null,
        'currentBlockId': null,
      });
    });
  }

  Future<void> performAction(String roomId, CoupActionModel actionModel) async {
    final gameRef = _games.doc(roomId);
    final actionRef = _actionsRef(roomId).doc();

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) return;

      final game = gameSnap.data()!;
      if ((game['status'] as String?) != 'playing' || (game['phase'] as String?) != 'action') {
        return;
      }

      final currentTurn = game['currentTurnPlayerId'] as String?;
      if (currentTurn != actionModel.source.name) {
        return;
      }

      final actorRef = _playersRef(roomId).doc(actionModel.source.name);
      final actorSnap = await tx.get(actorRef);
      if (!actorSnap.exists || actorSnap.data() == null) return;

      final actorData = actorSnap.data()!;
      final actorCoins = (actorData['coins'] as int?) ?? 0;
      final actorAlive = (actorData['alive'] as bool?) ?? true;
      if (!actorAlive) return;

      final action = actionModel.actionType;
      if (actorCoins >= 10 && action != CoupActionType.coup) {
        throw Exception('Must perform coup when having 10+ coins');
      }

      final targetId = actionModel.target?.name;
      if (CoupFunction.isNeedPlayerTarget(action) && targetId == null) {
        throw Exception('Target is required for this action');
      }

      if (targetId != null) {
        final targetSnap = await tx.get(_playersRef(roomId).doc(targetId));
        if (!targetSnap.exists || targetSnap.data() == null) {
          throw Exception('Target player not found');
        }
        final targetAlive = (targetSnap.data()!['alive'] as bool?) ?? true;
        if (!targetAlive) {
          throw Exception('Target is eliminated');
        }
      }

      var updatedCoins = actorCoins;
      if (action == CoupActionType.coup) {
        if (actorCoins < 7) throw Exception('Not enough coins for coup');
        updatedCoins -= 7;
      } else if (action == CoupActionType.assassin) {
        if (actorCoins < 3) throw Exception('Not enough coins for assassinate');
        updatedCoins -= 3;
      }

      if (updatedCoins != actorCoins) {
        tx.update(actorRef, {'coins': updatedCoins});
      }

      final claimedRole = action.claimedRole;
      final canChallenge = action.isChallengeable;
      final canBlock = action.isBlockable;

      tx.set(actionRef, {
        'type': action.firestoreType,
        'playerId': actionModel.source.name,
        'targetId': targetId,
        'status': 'pending',
        'claimedCard': claimedRole?.firestoreValue,
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'challengePasses': <String>[actionModel.source.name],
        'blockPasses': <String>[],
      });

      if (canChallenge) {
        tx.update(gameRef, {
          'phase': 'challenge',
          'currentActionId': actionRef.id,
          'currentBlockId': null,
        });
      } else if (canBlock) {
        tx.update(gameRef, {
          'phase': 'block',
          'currentActionId': actionRef.id,
          'currentBlockId': null,
        });
      } else {
        await _resolveActionSuccessInTransaction(
          tx,
          roomId: roomId,
          gameRef: gameRef,
          gameData: game,
          actionRef: actionRef,
          actionData: {
            'type': action.firestoreType,
            'playerId': actionModel.source.name,
            'targetId': targetId,
          },
        );
      }
    });
  }

  Future<void> respondToChallenge(
    String roomId,
    String playerId, {
    required bool challenge,
  }) async {
    final gameRef = _games.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) return;

      final game = gameSnap.data()!;
      if ((game['phase'] as String?) != 'challenge') return;

      final actionId = game['currentActionId'] as String?;
      if (actionId == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final actionSnap = await tx.get(actionRef);
      if (!actionSnap.exists || actionSnap.data() == null) return;

      final action = actionSnap.data()!;
      final actorId = action['playerId'] as String;
      final passes = (action['challengePasses'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toSet();

      if (challenge) {
        if (playerId == actorId || passes.contains(playerId)) return;

        final actorRef = _playersRef(roomId).doc(actorId);
        final challengerRef = _playersRef(roomId).doc(playerId);
        final actorSnap = await tx.get(actorRef);
        final challengerSnap = await tx.get(challengerRef);
        if (!actorSnap.exists || !challengerSnap.exists) return;

        final claimedCard = action['claimedCard'] as String?;
        final actorHasClaim = _playerHasCard(actorSnap.data()!, claimedCard);

        final challengeRef = _challengesRef(roomId).doc();
        tx.set(challengeRef, {
          'actionId': actionId,
          'challengerId': playerId,
          'result': actorHasClaim ? 'fail' : 'success',
          'resolvedAt': FieldValue.serverTimestamp(),
        });

        if (actorHasClaim) {
          _loseOneInfluenceInTransaction(tx, challengerRef, challengerSnap.data()!);
          _exchangeClaimedCardWithDeck(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerRef: actorRef,
            playerData: actorSnap.data()!,
            claimedCard: claimedCard,
          );

          if (_isActionBlockable(action['type'] as String)) {
            tx.update(gameRef, {'phase': 'block'});
          } else {
            await _resolveActionSuccessInTransaction(
              tx,
              roomId: roomId,
              gameRef: gameRef,
              gameData: game,
              actionRef: actionRef,
              actionData: action,
            );
          }
        } else {
          _loseOneInfluenceInTransaction(tx, actorRef, actorSnap.data()!);
          tx.update(actionRef, {
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
          await _rotateTurnOrFinish(tx, roomId: roomId, gameRef: gameRef, gameData: game);
        }

        return;
      }

      if (!passes.contains(playerId)) {
        passes.add(playerId);
        tx.update(actionRef, {'challengePasses': passes.toList()});
      }

      final alivePlayerIds = await _alivePlayerIdsInOrder(tx, roomId, game);
      final neededPasses = alivePlayerIds.where((id) => id != actorId).toSet();
      if (passes.containsAll(neededPasses)) {
        if (_isActionBlockable(action['type'] as String)) {
          tx.update(gameRef, {'phase': 'block'});
        } else {
          await _resolveActionSuccessInTransaction(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            actionRef: actionRef,
            actionData: action,
          );
        }
      }
    });
  }

  Future<void> respondToBlockOpportunity(
    String roomId,
    String playerId, {
    required bool block,
    String? claimedCard,
  }) async {
    final gameRef = _games.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) return;

      final game = gameSnap.data()!;
      if ((game['phase'] as String?) != 'block') return;

      final actionId = game['currentActionId'] as String?;
      if (actionId == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final actionSnap = await tx.get(actionRef);
      if (!actionSnap.exists || actionSnap.data() == null) return;
      final action = actionSnap.data()!;

      final actorId = action['playerId'] as String;
      final targetId = action['targetId'] as String?;
      final actionType = action['type'] as String;
      final allowedBlockCards = _allowedBlockCards(actionType);
      final eligibleBlockers = _eligibleBlockers(
        actionType: actionType,
        actorId: actorId,
        targetId: targetId,
        alivePlayerIds: await _alivePlayerIdsInOrder(tx, roomId, game),
      );

      if (!eligibleBlockers.contains(playerId)) return;

      if (block) {
        if (claimedCard == null || !allowedBlockCards.contains(claimedCard)) return;

        final blockRef = _blocksRef(roomId).doc();
        tx.set(blockRef, {
          'actionId': actionId,
          'blockerId': playerId,
          'claimedCard': claimedCard,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'challengePasses': <String>[playerId],
        });

        tx.update(gameRef, {
          'phase': 'block_challenge',
          'currentBlockId': blockRef.id,
        });
        return;
      }

      final passes = (action['blockPasses'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toSet();
      if (!passes.contains(playerId)) {
        passes.add(playerId);
        tx.update(actionRef, {'blockPasses': passes.toList()});
      }

      if (passes.containsAll(eligibleBlockers)) {
        await _resolveActionSuccessInTransaction(
          tx,
          roomId: roomId,
          gameRef: gameRef,
          gameData: game,
          actionRef: actionRef,
          actionData: action,
        );
      }
    });
  }

  Future<void> respondToBlockChallenge(
    String roomId,
    String playerId, {
    required bool challenge,
  }) async {
    final gameRef = _games.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) return;
      final game = gameSnap.data()!;
      if ((game['phase'] as String?) != 'block_challenge') return;

      final actionId = game['currentActionId'] as String?;
      final blockId = game['currentBlockId'] as String?;
      if (actionId == null || blockId == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final blockRef = _blocksRef(roomId).doc(blockId);
      final actionSnap = await tx.get(actionRef);
      final blockSnap = await tx.get(blockRef);
      if (!actionSnap.exists || !blockSnap.exists) return;

      final action = actionSnap.data()!;
      final blockData = blockSnap.data()!;
      final blockerId = blockData['blockerId'] as String;
      final challengePasses = (blockData['challengePasses'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toSet();

      if (challenge) {
        if (playerId == blockerId || challengePasses.contains(playerId)) return;

        final blockerRef = _playersRef(roomId).doc(blockerId);
        final challengerRef = _playersRef(roomId).doc(playerId);
        final blockerSnap = await tx.get(blockerRef);
        final challengerSnap = await tx.get(challengerRef);
        if (!blockerSnap.exists || !challengerSnap.exists) return;

        final claimedCard = blockData['claimedCard'] as String?;
        final blockerHasCard = _playerHasCard(blockerSnap.data()!, claimedCard);

        final challengeRef = _challengesRef(roomId).doc();
        tx.set(challengeRef, {
          'actionId': actionId,
          'challengerId': playerId,
          'result': blockerHasCard ? 'fail' : 'success',
          'resolvedAt': FieldValue.serverTimestamp(),
        });

        if (blockerHasCard) {
          _loseOneInfluenceInTransaction(tx, challengerRef, challengerSnap.data()!);
          _exchangeClaimedCardWithDeck(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerRef: blockerRef,
            playerData: blockerSnap.data()!,
            claimedCard: claimedCard,
          );
          tx.update(blockRef, {'status': 'resolved'});
          tx.update(actionRef, {
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
          await _rotateTurnOrFinish(tx, roomId: roomId, gameRef: gameRef, gameData: game);
        } else {
          _loseOneInfluenceInTransaction(tx, blockerRef, blockerSnap.data()!);
          tx.update(blockRef, {'status': 'resolved'});
          await _resolveActionSuccessInTransaction(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            actionRef: actionRef,
            actionData: action,
          );
        }

        return;
      }

      if (!challengePasses.contains(playerId)) {
        challengePasses.add(playerId);
        tx.update(blockRef, {'challengePasses': challengePasses.toList()});
      }

      final alivePlayerIds = await _alivePlayerIdsInOrder(tx, roomId, game);
      final neededPasses = alivePlayerIds.where((id) => id != blockerId).toSet();
      if (challengePasses.containsAll(neededPasses)) {
        tx.update(blockRef, {'status': 'resolved'});
        tx.update(actionRef, {
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
        await _rotateTurnOrFinish(tx, roomId: roomId, gameRef: gameRef, gameData: game);
      }
    });
  }

  Future<void> processBots(String roomId) async {
    final room = await getRoom(roomId);
    if (room.roomState != GameState.playing) return;

    final bot = room.players.firstWhereOrNull((p) => p.name == room.currentTurn && p.isBot && p.isAlive);

    if (room.phase == GamePhase.action && bot != null) {
      final action = _chooseBotAction(room, bot);
      final targets = room.players.where((p) => p.isAlive && p.name != bot.name).toList();
      final target = targets.isNotEmpty ? targets[_random.nextInt(targets.length)] : null;
      await performAction(
        roomId,
        CoupActionModel(source: bot, actionType: action, target: target),
      );
      return;
    }

    final currentAction = room.currentAction;
    if (currentAction == null) return;

    if (room.phase == GamePhase.challenge) {
      final pending = room.players.firstWhereOrNull(
        (p) =>
            p.isBot &&
            p.isAlive &&
            p.name != currentAction.source.name &&
            !(currentAction.listNeedVote.contains(p.name) || currentAction.listVoted.contains(p.name)),
      );
      if (pending != null) {
        final shouldChallenge = _random.nextInt(100) < 18;
        await respondToChallenge(roomId, pending.name, challenge: shouldChallenge);
      }
      return;
    }

    if (room.phase == GamePhase.block) {
      final actionType = currentAction.actionType;
      final canBotBlock = room.players.where((p) {
        if (!p.isBot || !p.isAlive) return false;
        if (actionType == CoupActionType.foreignAid) return p.name != currentAction.source.name;
        return p.name == currentAction.target?.name;
      }).toList();
      if (canBotBlock.isNotEmpty) {
        final blocker = canBotBlock.first;
        final willBlock = _random.nextInt(100) < 40;
        final cards = _allowedBlockCards(actionType.firestoreType);
        await respondToBlockOpportunity(
          roomId,
          blocker.name,
          block: willBlock,
          claimedCard: willBlock && cards.isNotEmpty ? cards.first : null,
        );
      }
      return;
    }

    if (room.phase == GamePhase.blockChallenge) {
      final blockerId = currentAction.blockerId;
      final pending = room.players.firstWhereOrNull(
        (p) => p.isBot && p.isAlive && p.name != blockerId,
      );
      if (pending != null) {
        final shouldChallenge = _random.nextInt(100) < 20;
        await respondToBlockChallenge(roomId, pending.name, challenge: shouldChallenge);
      }
    }
  }

  CoupActionType _chooseBotAction(CoupRoomModel room, CoupPlayerModel bot) {
    if (bot.coins >= 7) return CoupActionType.coup;
    if (bot.coins < 3) return CoupActionType.income;

    final candidates = <CoupActionType>[
      CoupActionType.income,
      CoupActionType.foreignAid,
      CoupActionType.duke,
      CoupActionType.captain,
      CoupActionType.ambassador,
      CoupActionType.assassin,
    ];

    if (bot.coins >= 3) {
      candidates.add(CoupActionType.assassin);
    }

    if (bot.coins >= 10) {
      return CoupActionType.coup;
    }

    return candidates[_random.nextInt(candidates.length)];
  }

  Future<void> _resolveActionSuccessInTransaction(
    Transaction tx, {
    required String roomId,
    required DocumentReference<Map<String, dynamic>> gameRef,
    required Map<String, dynamic> gameData,
    required DocumentReference<Map<String, dynamic>> actionRef,
    required Map<String, dynamic> actionData,
  }) async {
    final actionType = actionData['type'] as String;
    final sourceId = actionData['playerId'] as String;
    final targetId = actionData['targetId'] as String?;

    final sourceRef = _playersRef(roomId).doc(sourceId);

    switch (actionType) {
      case 'income':
        tx.update(sourceRef, {'coins': FieldValue.increment(1)});
        break;
      case 'foreign_aid':
        tx.update(sourceRef, {'coins': FieldValue.increment(2)});
        break;
      case 'tax':
        tx.update(sourceRef, {'coins': FieldValue.increment(3)});
        break;
      case 'steal':
        if (targetId != null) {
          final targetRef = _playersRef(roomId).doc(targetId);
          await _applySteal(tx, sourceRef, targetRef);
        }
        break;
      case 'assassinate':
        if (targetId != null) {
          final targetRef = _playersRef(roomId).doc(targetId);
          await _loseOneInfluenceByRef(tx, targetRef);
        }
        break;
      case 'coup':
        if (targetId != null) {
          final targetRef = _playersRef(roomId).doc(targetId);
          await _loseOneInfluenceByRef(tx, targetRef);
        }
        break;
      case 'exchange':
        await _applyExchange(
          tx,
          roomId: roomId,
          gameRef: gameRef,
          sourceRef: sourceRef,
          gameData: gameData,
        );
        break;
      default:
        break;
    }

    tx.update(actionRef, {
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    await _rotateTurnOrFinish(tx, roomId: roomId, gameRef: gameRef, gameData: gameData);
  }

  Future<void> _applySteal(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> sourceRef,
    DocumentReference<Map<String, dynamic>> targetRef,
  ) async {
    final targetSnap = await tx.get(targetRef);
    if (!targetSnap.exists || targetSnap.data() == null) return;

    final targetCoins = (targetSnap.data()!['coins'] as int?) ?? 0;
    final transfer = targetCoins >= 2 ? 2 : targetCoins;
    if (transfer <= 0) return;

    tx.update(targetRef, {'coins': targetCoins - transfer});
    tx.update(sourceRef, {'coins': FieldValue.increment(transfer)});
  }

  Future<void> _applyExchange(
    Transaction tx, {
    required String roomId,
    required DocumentReference<Map<String, dynamic>> gameRef,
    required DocumentReference<Map<String, dynamic>> sourceRef,
    required Map<String, dynamic> gameData,
  }) async {
    final sourceSnap = await tx.get(sourceRef);
    if (!sourceSnap.exists || sourceSnap.data() == null) return;

    final deck = (gameData['deck'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList();
    if (deck.length < 2) return;

    final player = sourceSnap.data()!;
    final influences = (player['influences'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList();
    final revealed = (player['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    final drawA = deck.removeLast();
    final drawB = deck.removeLast();
    final pool = <String>[...influences, drawA, drawB]..shuffle(_random);
    final keep = pool.take(2).toList();
    final returns = pool.skip(2).toList();
    deck.addAll(returns);
    deck.shuffle(_random);

    tx.update(sourceRef, {
      'influences': keep,
      'revealedInfluences': revealed,
    });
    tx.update(gameRef, {'deck': deck});
  }

  Future<List<String>> _alivePlayerIdsInOrder(
    Transaction tx,
    String roomId,
    Map<String, dynamic> game,
  ) async {
    final order = (game['playerOrder'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    final alive = <String>[];
    for (final playerId in order) {
      final playerSnap = await tx.get(_playersRef(roomId).doc(playerId));
      if (!playerSnap.exists || playerSnap.data() == null) continue;
      if ((playerSnap.data()!['alive'] as bool?) ?? true) {
        alive.add(playerId);
      }
    }
    return alive;
  }

  Future<void> _rotateTurnOrFinish(
    Transaction tx, {
    required String roomId,
    required DocumentReference<Map<String, dynamic>> gameRef,
    required Map<String, dynamic> gameData,
  }) async {
    final order = (gameData['playerOrder'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    if (order.isEmpty) return;

    final alive = await _alivePlayerIdsInOrder(tx, roomId, gameData);
    if (alive.length <= 1) {
      tx.update(gameRef, {
        'status': 'finished',
        'phase': 'finished',
        'winnerId': alive.isEmpty ? null : alive.first,
        'currentActionId': null,
        'currentBlockId': null,
      });
      return;
    }

    final current = (gameData['currentTurnPlayerId'] as String?) ?? order.first;
    final currentIndex = order.indexOf(current);
    var cursor = currentIndex == -1 ? 0 : currentIndex;

    for (var i = 0; i < order.length; i++) {
      cursor = (cursor + 1) % order.length;
      final candidate = order[cursor];
      if (alive.contains(candidate)) {
        tx.update(gameRef, {
          'phase': 'action',
          'currentTurnPlayerId': candidate,
          'currentActionId': null,
          'currentBlockId': null,
        });
        return;
      }
    }
  }

  Future<void> _loseOneInfluenceByRef(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> playerRef,
  ) async {
    final playerSnap = await tx.get(playerRef);
    if (!playerSnap.exists || playerSnap.data() == null) return;
    _loseOneInfluenceInTransaction(tx, playerRef, playerSnap.data()!);
  }

  void _loseOneInfluenceInTransaction(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> playerRef,
    Map<String, dynamic> playerData,
  ) {
    final influences = (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final revealed = (playerData['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    if (influences.isEmpty) {
      tx.update(playerRef, {'alive': false});
      return;
    }

    final lost = influences.removeAt(0);
    revealed.add(lost);

    tx.update(playerRef, {
      'influences': influences,
      'revealedInfluences': revealed,
      'alive': influences.isNotEmpty,
    });
  }

  void _exchangeClaimedCardWithDeck(
    Transaction tx, {
    required String roomId,
    required DocumentReference<Map<String, dynamic>> gameRef,
    required Map<String, dynamic> gameData,
    required DocumentReference<Map<String, dynamic>> playerRef,
    required Map<String, dynamic> playerData,
    required String? claimedCard,
  }) {
    if (claimedCard == null) return;

    final influences = (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final index = influences.indexOf(claimedCard);
    if (index == -1) return;

    final deck = (gameData['deck'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList();
    if (deck.isEmpty) return;

    final old = influences[index];
    final replacement = deck.removeLast();
    influences[index] = replacement;
    deck.add(old);
    deck.shuffle(_random);

    tx.update(playerRef, {'influences': influences});
    tx.update(gameRef, {'deck': deck});
  }

  bool _playerHasCard(Map<String, dynamic> playerData, String? claimedCard) {
    if (claimedCard == null) return false;
    final influences = (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    return influences.contains(claimedCard);
  }

  bool _isActionBlockable(String actionType) {
    return actionType == 'foreign_aid' || actionType == 'assassinate' || actionType == 'steal';
  }

  Set<String> _eligibleBlockers({
    required String actionType,
    required String actorId,
    required String? targetId,
    required List<String> alivePlayerIds,
  }) {
    if (actionType == 'foreign_aid') {
      return alivePlayerIds.where((id) => id != actorId).toSet();
    }

    if (actionType == 'assassinate' || actionType == 'steal') {
      if (targetId == null) return <String>{};
      return <String>{targetId};
    }

    return <String>{};
  }

  Set<String> _allowedBlockCards(String actionType) {
    switch (actionType) {
      case 'foreign_aid':
        return <String>{'duke'};
      case 'assassinate':
        return <String>{'contessa'};
      case 'steal':
        return <String>{'captain', 'ambassador'};
      default:
        return <String>{};
    }
  }

  CoupPlayerModel _playerFromFirestore(String playerId, Map<String, dynamic> data) {
    final influences = (data['influences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final revealed = (data['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    final cards = <CoupCardModel>[
      ...influences.map((v) => CoupCardModel(roleType: CoupRoleTypeX.fromFirestoreValue(v), isRevealed: false)),
      ...revealed.map((v) => CoupCardModel(roleType: CoupRoleTypeX.fromFirestoreValue(v), isRevealed: true)),
    ];

    return CoupPlayerModel(
      name: playerId,
      isReady: (data['isReady'] as bool?) ?? true,
      cards: cards,
      isAlive: (data['alive'] as bool?) ?? true,
      coins: (data['coins'] as int?) ?? 2,
      isBot: (data['isBot'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> _playerToFirestore(CoupPlayerModel player) {
    final influences = player.cards.where((e) => !e.isRevealed).map((e) => e.roleType.firestoreValue).toList();
    final revealed = player.cards.where((e) => e.isRevealed).map((e) => e.roleType.firestoreValue).toList();

    return {
      'name': player.name,
      'isBot': player.isBot,
      'coins': player.coins,
      'influences': influences,
      'revealedInfluences': revealed,
      'alive': player.isAlive,
      'joinedAt': FieldValue.serverTimestamp(),
      'isReady': player.isReady,
    };
  }

  CoupActionModel _actionFromFirestore(
    String actionId,
    Map<String, dynamic> action,
    List<CoupPlayerModel> players,
  ) {
    final sourceId = action['playerId'] as String? ?? '';
    final targetId = action['targetId'] as String?;

    final source = players.firstWhereOrNull((p) => p.name == sourceId) ??
        CoupPlayerModel(name: sourceId, isReady: true, cards: const [], isAlive: true, coins: 0);
    final target = targetId == null ? null : players.firstWhereOrNull((p) => p.name == targetId);

    final challengePasses = (action['challengePasses'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final blockPasses = (action['blockPasses'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    return CoupActionModel(
      actionId: actionId,
      source: source,
      target: target,
      actionType: CoupActionTypeX.fromFirestoreType((action['type'] as String?) ?? 'income'),
      status: action['status'] as String?,
      claimedCard: action['claimedCard'] as String?,
      blockerId: action['blockerId'] as String?,
      blockClaimedCard: action['blockClaimedCard'] as String?,
    )
      ..listNeedVote = challengePasses
      ..listVoted = blockPasses;
  }

  List<String> _generateStandardDeck() {
    final roles = <String>[
      'duke',
      'duke',
      'duke',
      'assassin',
      'assassin',
      'assassin',
      'captain',
      'captain',
      'captain',
      'ambassador',
      'ambassador',
      'ambassador',
      'contessa',
      'contessa',
      'contessa',
    ];
    roles.shuffle(_random);
    return roles;
  }
}
