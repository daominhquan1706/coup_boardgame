import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/model/game_history_entry.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/utils/constants.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  static const String _revealReasonChallengeActorLost = 'challenge_actor_lost';
  static const String _revealReasonChallengeChallengerLost =
      'challenge_challenger_lost';
  static const String _revealReasonBlockChallengeBlockerLost =
      'block_challenge_blocker_lost';
  static const String _revealReasonBlockChallengeChallengerLost =
      'block_challenge_challenger_lost';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection('games');

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

  Future<bool> createRoom(String roomId, List<String> players,
      {String? hostDisplayName}) async {
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
            displayName: hostDisplayName,
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
    final players = playersSnap.docs
        .map((doc) => _playerFromFirestore(doc.id, doc.data()))
        .toList();

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
        currentAction =
            _actionFromFirestore(actionId, actionDoc.data()!, players);
      }
    }

    final deckStrings = (game['deck'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    return CoupRoomModel(
      roomId: roomId,
      players: players,
      roomState:
          GameStateExtension.fromName((game['status'] as String?) ?? 'waiting'),
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
    return Stream<CoupRoomModel>.multi((controller) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? gameSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? playersSub;
      var isFetching = false;
      var hasPending = false;

      Future<void> emitLatest() async {
        if (isFetching) {
          hasPending = true;
          return;
        }

        isFetching = true;
        do {
          hasPending = false;
          try {
            final latest = await getRoom(roomId);
            controller.add(latest);
          } catch (e, st) {
            controller.addError(e, st);
          }
        } while (hasPending);
        isFetching = false;
      }

      void scheduleEmit() {
        unawaited(emitLatest());
      }

      gameSub = _games.doc(roomId).snapshots().listen(
            (_) => scheduleEmit(),
            onError: controller.addError,
          );

      playersSub = _playersRef(roomId).snapshots().listen(
            (_) => scheduleEmit(),
            onError: controller.addError,
          );

      // Emit immediately so UI has initial data before first snapshot event.
      scheduleEmit();

      controller.onCancel = () async {
        await gameSub?.cancel();
        await playersSub?.cancel();
      };
    });
  }

  Stream<List<GameHistoryEntry>> getActionHistoryStream(String roomId) {
    return _actionsRef(roomId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final logs = <GameHistoryEntry>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final actionType = data['type'] as String? ?? 'income';
        final actorId = data['playerId'] as String? ?? 'Unknown';
        final targetId = data['targetId'] as String?;
        final claimedCard = data['claimedCard'] as String?;
        final status = data['status'] as String?;
        final createdAt = data['createdAt'];
        final actionTime = createdAt is Timestamp ? createdAt.toDate() : null;

        final events = data['eventLogs'] as List<dynamic>?;
        if (events == null || events.isEmpty) {
          logs.add(GameHistoryEntry(
            id: doc.id,
            eventType: 'action_played',
            actorName: actorId,
            actionType: actionType,
            targetName: targetId,
            claimedCard: claimedCard,
            status: status,
            createdAt: actionTime,
          ));
          continue;
        }

        for (var i = 0; i < events.length; i++) {
          final event = events[i];
          if (event is! Map<String, dynamic>) continue;
          final tsMs = event['tsMs'] as int?;
          logs.add(GameHistoryEntry(
            id: '${doc.id}#$i',
            eventType: event['eventType'] as String? ?? 'action_played',
            actorName: event['actorId'] as String? ?? actorId,
            actionType: event['actionType'] as String? ?? actionType,
            targetName: event['targetId'] as String? ?? targetId,
            claimedCard: event['claimedCard'] as String? ?? claimedCard,
            coinDelta: event['coinDelta'] as int?,
            status: status,
            createdAt: tsMs == null
                ? actionTime?.add(Duration(milliseconds: i))
                : DateTime.fromMillisecondsSinceEpoch(tsMs),
          ));
        }
      }

      logs.sort((a, b) {
        final aMs = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bMs = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bMs.compareTo(aMs);
      });

      return logs.toList(growable: false);
    });
  }

  Future<void> _clearRoundArtifacts(String roomId) async {
    Future<void> clearCollection(
        CollectionReference<Map<String, dynamic>> ref) async {
      final snap = await ref.get();
      if (snap.docs.isEmpty) return;

      var batch = _firestore.batch();
      var count = 0;
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
    }

    await clearCollection(_actionsRef(roomId));
    await clearCollection(_blocksRef(roomId));
    await clearCollection(_challengesRef(roomId));
  }

  List<Map<String, dynamic>> _appendActionEvent(
    List<dynamic>? existingEvents, {
    required String eventType,
    required String actorId,
    required String actionType,
    String? targetId,
    String? claimedCard,
    int? coinDelta,
  }) {
    final events = (existingEvents ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    events.add({
      'eventType': eventType,
      'actorId': actorId,
      'actionType': actionType,
      'targetId': targetId,
      'claimedCard': claimedCard,
      'coinDelta': coinDelta,
      'tsMs': DateTime.now().millisecondsSinceEpoch,
    });

    return events;
  }

  Future<Map<String, dynamic>?> _getGameDataInPhase(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> gameRef, {
    String? expectedPhase,
  }) async {
    final gameSnap = await tx.get(gameRef);
    if (!gameSnap.exists || gameSnap.data() == null) return null;

    final gameData = gameSnap.data()!;
    if (expectedPhase != null &&
        (gameData['phase'] as String?) != expectedPhase) {
      return null;
    }

    return gameData;
  }

  Future<Map<String, dynamic>?> _getActionData(
    Transaction tx,
    String roomId,
    String? actionId,
  ) async {
    if (actionId == null) return null;
    final actionSnap = await tx.get(_actionsRef(roomId).doc(actionId));
    if (!actionSnap.exists || actionSnap.data() == null) return null;
    return actionSnap.data()!;
  }

  Future<Map<String, dynamic>?> _getBlockData(
    Transaction tx,
    String roomId,
    String? blockId,
  ) async {
    if (blockId == null) return null;
    final blockSnap = await tx.get(_blocksRef(roomId).doc(blockId));
    if (!blockSnap.exists || blockSnap.data() == null) return null;
    return blockSnap.data()!;
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

        final existingPlayer = await tx.get(playerRef);
        if (existingPlayer.exists) {
          final updateData = <String, dynamic>{};
          final display = player.displayName?.trim();
          if (display != null && display.isNotEmpty) {
            updateData['displayName'] = display;
          }
          if (updateData.isNotEmpty) {
            tx.update(playerRef, updateData);
          }
          return;
        }

        final count = (game['playersCount'] as int?) ?? 0;
        if (count >= Constant.maxPlayersPerRoom) {
          throw JoinRoomError('Room is full');
        }

        tx.update(gameRef, {
          'playersCount': count + 1,
          'playerOrder': FieldValue.arrayUnion(<String>[player.name]),
        });
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
        displayName: 'BOT_$suffix',
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
    final botsSnap = await _playersRef(roomId)
        .where('isBot', isEqualTo: true)
        .limit(1)
        .get();
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

    final playerDoc = await _playersRef(roomId).doc(userName).get();
    if (playerDoc.exists) {
      // Player already exists in this room - allow rejoin if game is still waiting
      // This handles the case where user was disconnected or redirected unexpectedly
      return true;
    }

    final count = (game.data()!['playersCount'] as int?) ?? 0;
    if (count >= Constant.maxPlayersPerRoom) {
      throw JoinRoomError('Room is full');
    }

    return true;
  }

  Future<void> updatePlayerReady(String roomId, String playerId,
      {required bool isReady}) async {
    final gameRef = _games.doc(roomId);
    final playerRef = _playersRef(roomId).doc(playerId);

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      final playerSnap = await tx.get(playerRef);
      if (!gameSnap.exists ||
          !playerSnap.exists ||
          gameSnap.data() == null ||
          playerSnap.data() == null) {
        return;
      }

      final game = gameSnap.data()!;
      if ((game['status'] as String?) != 'waiting') return;

      final isBot = (playerSnap.data()!['isBot'] as bool?) ?? false;
      final isHost = (game['hostId'] as String?) == playerId;
      tx.update(playerRef, {'isReady': (isBot || isHost) ? true : isReady});
    });
  }

  /// Updates the player's display name in the given room.
  ///
  /// Returns `true` if the transaction actually wrote a value, `false`
  /// otherwise (e.g. the game was already playing or the name was empty).
  Future<bool> updatePlayerDisplayName(
      String roomId, String playerId, String displayName) async {
    final gameRef = _games.doc(roomId);
    final playerRef = _playersRef(roomId).doc(playerId);
    var didWrite = false;

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      final playerSnap = await tx.get(playerRef);
      if (!gameSnap.exists ||
          !playerSnap.exists ||
          gameSnap.data() == null ||
          playerSnap.data() == null) {
        return;
      }

      final normalized = displayName.trim();
      if (normalized.isEmpty) return;

      // allow updating display name at any time; don't block on game state
      tx.update(playerRef, {'displayName': normalized});
      didWrite = true;
    });

    return didWrite;
  }

  Future<void> kickPlayer(String roomId,
      {required String hostId, required String targetPlayerId}) async {
    if (hostId == targetPlayerId) return;

    final gameRef = _games.doc(roomId);
    final targetRef = _playersRef(roomId).doc(targetPlayerId);

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      final targetSnap = await tx.get(targetRef);
      if (!gameSnap.exists || gameSnap.data() == null || !targetSnap.exists) {
        return;
      }

      final game = gameSnap.data()!;
      if ((game['status'] as String?) != 'waiting') return;
      if ((game['hostId'] as String?) != hostId) return;

      final count = (game['playersCount'] as int?) ?? 0;
      tx.delete(targetRef);
      tx.update(gameRef, {
        'playersCount': count > 0 ? count - 1 : 0,
        'playerOrder': FieldValue.arrayRemove(<String>[targetPlayerId]),
      });
    });
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

    await _clearRoundArtifacts(roomId);

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

      final playerIds = playersSnap.docs.map((e) => e.id).toList();
      final roundRandom = Random(
        DateTime.now().microsecondsSinceEpoch ^
            roomId.hashCode ^
            playersSnap.docs.length,
      );
      playerIds.shuffle(roundRandom);
      final firstTurnPlayerId =
          playerIds[roundRandom.nextInt(playerIds.length)];
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
        'currentTurnPlayerId': firstTurnPlayerId,
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
      final gameSnap = await tx.get(gameRef);
      final gameData = gameSnap.data();
      final hostId = gameData == null ? null : gameData['hostId'] as String?;

      for (final player in players.docs) {
        final isBot = (player.data()['isBot'] as bool?) ?? false;
        final isHost = hostId != null && player.id == hostId;
        tx.update(player.reference, {
          'coins': 2,
          'alive': true,
          'influences': <String>[],
          'revealedInfluences': <String>[],
          'isReady': isBot || isHost,
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

  Future<void> performAction(
    String roomId,
    CoupActionModel actionModel, {
    List<String>? exchangeKeepInfluences,
  }) async {
    final gameRef = _games.doc(roomId);
    final actionRef = _actionsRef(roomId).doc();
    final exchangeKeep = (exchangeKeepInfluences ?? const <String>[])
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    await _firestore.runTransaction((tx) async {
      final gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists || gameSnap.data() == null) return;

      final game = gameSnap.data()!;
      if ((game['status'] as String?) != 'playing' ||
          (game['phase'] as String?) != 'action') {
        return;
      }

      final currentTurn = game['currentTurnPlayerId'] as String?;
      if (currentTurn != actionModel.source.name) {
        return;
      }

      final playerStates = await _loadPlayerStatesInOrder(tx, roomId, game);

      final actorRef = _playersRef(roomId).doc(actionModel.source.name);
      final actorData = playerStates[actionModel.source.name];
      if (actorData == null) return;
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
        if (targetId == actionModel.source.name) {
          throw Exception('Cannot target yourself');
        }
        final targetData = playerStates[targetId];
        if (targetData == null) {
          throw Exception('Target player not found');
        }
        final targetAlive = (targetData['alive'] as bool?) ?? true;
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
      final canBlock = action.isBlockable || action == CoupActionType.coup;
      var initialEvents = _appendActionEvent(
        null,
        eventType: 'action_played',
        actorId: actionModel.source.name,
        actionType: action.firestoreType,
        targetId: targetId,
        claimedCard: claimedRole?.firestoreValue,
      );
      if (action == CoupActionType.coup) {
        initialEvents = _appendActionEvent(
          initialEvents,
          eventType: 'coins_changed',
          actorId: actionModel.source.name,
          actionType: action.firestoreType,
          coinDelta: -7,
        );
      } else if (action == CoupActionType.assassin) {
        initialEvents = _appendActionEvent(
          initialEvents,
          eventType: 'coins_changed',
          actorId: actionModel.source.name,
          actionType: action.firestoreType,
          coinDelta: -3,
        );
      }

      final actionPayload = <String, dynamic>{
        'type': action.firestoreType,
        'playerId': actionModel.source.name,
        'targetId': targetId,
        'status': 'pending',
        'claimedCard': claimedRole?.firestoreValue,
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'challengePasses': <String>[actionModel.source.name],
        'blockPasses': <String>[],
        'eventLogs': initialEvents,
      };
      if (action == CoupActionType.ambassador && exchangeKeep.isNotEmpty) {
        actionPayload['exchangeKeepInfluences'] = exchangeKeep;
      }
      tx.set(actionRef, actionPayload);

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
          playerStates: playerStates,
          actionData: {
            'type': action.firestoreType,
            'playerId': actionModel.source.name,
            'targetId': targetId,
            'exchangeKeepInfluences': exchangeKeep,
          },
          actionEventLogs: initialEvents,
        );
      }
    });
  }

  Future<void> submitExchangeSelection(
    String roomId,
    String playerId, {
    required List<String> keepInfluences,
  }) async {
    final gameRef = _games.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final game =
          await _getGameDataInPhase(tx, gameRef, expectedPhase: 'resolve');
      if (game == null) return;

      final actionId = game['currentActionId'] as String?;
      if (actionId == null) return;

      final action = await _getActionData(tx, roomId, actionId);
      if (action == null) return;
      if ((action['type'] as String?) != 'exchange') return;
      if ((action['status'] as String?) != 'awaiting_exchange_selection') {
        return;
      }

      final actorId = action['playerId'] as String?;
      if (actorId != playerId) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final playerStates = await _loadPlayerStatesInOrder(tx, roomId, game);

      final normalizedKeep = keepInfluences
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      await _resolveActionSuccessInTransaction(
        tx,
        roomId: roomId,
        gameRef: gameRef,
        gameData: game,
        actionRef: actionRef,
        playerStates: playerStates,
        actionData: {
          ...action,
          'exchangeKeepInfluences': normalizedKeep,
        },
        actionEventLogs: action['eventLogs'] as List<dynamic>?,
      );
    });
  }

  Future<void> submitRevealSelection(
    String roomId,
    String playerId, {
    required String revealedInfluence,
  }) async {
    final gameRef = _games.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final game =
          await _getGameDataInPhase(tx, gameRef, expectedPhase: 'resolve');
      if (game == null) return;

      final actionId = game['currentActionId'] as String?;
      if (actionId == null) return;

      final action = await _getActionData(tx, roomId, actionId);
      if (action == null) return;
      if ((action['status'] as String?) != 'awaiting_reveal_selection') return;

      final revealChooserId = action['revealChooserId'] as String?;
      final revealReason = action['revealSelectionReason'] as String?;
      final pendingBlockId = action['pendingBlockId'] as String?;
      if (revealChooserId != playerId || revealReason == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final blockRef = pendingBlockId == null
          ? null
          : _blocksRef(roomId).doc(pendingBlockId);
      final playerStates = await _loadPlayerStatesInOrder(tx, roomId, game);
      final chooserData = playerStates[playerId];
      if (chooserData == null) return;

      final influences =
          (chooserData['influences'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toList(growable: false);
      if (!influences.contains(revealedInfluence)) return;

      final actionType = action['type'] as String? ?? 'income';
      var actionEventLogs = action['eventLogs'] as List<dynamic>?;
      final chooserRef = _playersRef(roomId).doc(playerId);
      final revealedCard = _loseOneInfluenceInTransaction(
        tx,
        chooserRef,
        chooserData,
        playerStates: playerStates,
        playerId: playerId,
        preferredInfluence: revealedInfluence,
      );
      if (revealedCard != null) {
        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'influence_revealed',
          actorId: playerId,
          actionType: actionType,
          claimedCard: revealedCard,
        );
      }

      switch (revealReason) {
        case _revealReasonChallengeActorLost:
          tx.update(actionRef, {
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
            'eventLogs': actionEventLogs,
            'revealChooserId': null,
            'revealSelectionReason': null,
            'pendingBlockId': null,
          });
          await _rotateTurnOrFinish(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerStates: playerStates,
          );
          return;
        case _revealReasonChallengeChallengerLost:
          tx.update(actionRef, {
            'eventLogs': actionEventLogs,
            'revealChooserId': null,
            'revealSelectionReason': null,
            'pendingBlockId': null,
          });
          if (_isActionBlockable(actionType)) {
            tx.update(gameRef, {'phase': 'block'});
          } else {
            await _resolveActionSuccessInTransaction(
              tx,
              roomId: roomId,
              gameRef: gameRef,
              gameData: game,
              actionRef: actionRef,
              playerStates: playerStates,
              actionData: action,
              actionEventLogs: actionEventLogs,
            );
          }
          return;
        case _revealReasonBlockChallengeChallengerLost:
          if (blockRef != null) {
            tx.update(blockRef, {'status': 'resolved'});
          }
          tx.update(actionRef, {
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
            'eventLogs': actionEventLogs,
            'revealChooserId': null,
            'revealSelectionReason': null,
            'pendingBlockId': null,
          });
          await _rotateTurnOrFinish(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerStates: playerStates,
          );
          return;
        case _revealReasonBlockChallengeBlockerLost:
          if (blockRef != null) {
            tx.update(blockRef, {'status': 'resolved'});
          }
          tx.update(actionRef, {
            'eventLogs': actionEventLogs,
            'revealChooserId': null,
            'revealSelectionReason': null,
            'pendingBlockId': null,
          });
          await _resolveActionSuccessInTransaction(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            actionRef: actionRef,
            playerStates: playerStates,
            actionData: action,
            actionEventLogs: actionEventLogs,
          );
          return;
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
      final game =
          await _getGameDataInPhase(tx, gameRef, expectedPhase: 'challenge');
      if (game == null) return;

      final actionId = game['currentActionId'] as String?;
      if (actionId == null) return;

      final action = await _getActionData(tx, roomId, actionId);
      if (action == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final playerStates = await _loadPlayerStatesInOrder(tx, roomId, game);
      final actorId = action['playerId'] as String;
      final responderData = playerStates[playerId];
      final responderAlive = (responderData?['alive'] as bool?) ?? false;
      if (!responderAlive) return;
      var actionEventLogs = action['eventLogs'] as List<dynamic>?;
      final passes =
          (action['challengePasses'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toSet();

      if (challenge) {
        if (playerId == actorId || passes.contains(playerId)) return;
        final actionType = action['type'] as String? ?? 'income';

        final actorRef = _playersRef(roomId).doc(actorId);
        final challengerRef = _playersRef(roomId).doc(playerId);
        final actorData = playerStates[actorId];
        final challengerData = playerStates[playerId];
        if (actorData == null || challengerData == null) return;

        final claimedCard = action['claimedCard'] as String?;
        final actorHasClaim = _playerHasCard(actorData, claimedCard);

        final challengeRef = _challengesRef(roomId).doc();
        tx.set(challengeRef, {
          'actionId': actionId,
          'challengerId': playerId,
          'result': actorHasClaim ? 'fail' : 'success',
          'resolvedAt': FieldValue.serverTimestamp(),
        });

        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'challenge_called',
          actorId: playerId,
          actionType: actionType,
          targetId: actorId,
        );

        if (actorHasClaim) {
          final shouldAwaitReveal = _shouldAwaitRevealSelection(
            challengerData,
            playerId: playerId,
          );
          if (shouldAwaitReveal) {
            tx.update(actionRef, {
              'status': 'awaiting_reveal_selection',
              'revealChooserId': playerId,
              'revealSelectionReason': _revealReasonChallengeChallengerLost,
              'pendingBlockId': null,
              'eventLogs': actionEventLogs,
            });
            _exchangeClaimedCardWithDeck(
              tx,
              roomId: roomId,
              gameRef: gameRef,
              gameData: game,
              playerRef: actorRef,
              playerData: actorData,
              claimedCard: claimedCard,
            );
            tx.update(gameRef, {'phase': 'resolve'});
            return;
          }

          final revealedCard = _loseOneInfluenceInTransaction(
            tx,
            challengerRef,
            challengerData,
            playerStates: playerStates,
            playerId: playerId,
          );
          if (revealedCard != null) {
            actionEventLogs = _appendActionEvent(
              actionEventLogs,
              eventType: 'influence_revealed',
              actorId: playerId,
              actionType: actionType,
              claimedCard: revealedCard,
            );
          }
          tx.update(actionRef, {'eventLogs': actionEventLogs});
          _exchangeClaimedCardWithDeck(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerRef: actorRef,
            playerData: actorData,
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
              playerStates: playerStates,
              actionData: action,
              actionEventLogs: actionEventLogs,
            );
          }
        } else {
          final shouldAwaitReveal = _shouldAwaitRevealSelection(
            actorData,
            playerId: actorId,
          );
          if (shouldAwaitReveal) {
            tx.update(actionRef, {
              'status': 'awaiting_reveal_selection',
              'revealChooserId': actorId,
              'revealSelectionReason': _revealReasonChallengeActorLost,
              'pendingBlockId': null,
              'eventLogs': actionEventLogs,
            });
            tx.update(gameRef, {'phase': 'resolve'});
            return;
          }

          final revealedCard = _loseOneInfluenceInTransaction(
            tx,
            actorRef,
            actorData,
            playerStates: playerStates,
            playerId: actorId,
          );
          if (revealedCard != null) {
            actionEventLogs = _appendActionEvent(
              actionEventLogs,
              eventType: 'influence_revealed',
              actorId: actorId,
              actionType: actionType,
              claimedCard: revealedCard,
            );
          }
          tx.update(actionRef, {
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
            'eventLogs': actionEventLogs,
          });
          await _rotateTurnOrFinish(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerStates: playerStates,
          );
        }

        return;
      }

      if (!passes.contains(playerId)) {
        passes.add(playerId);
        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'challenge_pass',
          actorId: playerId,
          actionType: action['type'] as String? ?? 'income',
        );
        tx.update(actionRef, {
          'challengePasses': passes.toList(),
          'eventLogs': actionEventLogs,
        });
      }

      final alivePlayerIds = _alivePlayerIdsFromStates(playerStates, game);
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
            playerStates: playerStates,
            actionData: action,
            actionEventLogs: actionEventLogs,
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
    String? revealedInfluence,
  }) async {
    final gameRef = _games.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final game =
          await _getGameDataInPhase(tx, gameRef, expectedPhase: 'block');
      if (game == null) return;

      final actionId = game['currentActionId'] as String?;
      if (actionId == null) return;

      final action = await _getActionData(tx, roomId, actionId);
      if (action == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final playerStates = await _loadPlayerStatesInOrder(tx, roomId, game);

      final actorId = action['playerId'] as String;
      final targetId = action['targetId'] as String?;
      final actionType = action['type'] as String;
      var actionEventLogs = action['eventLogs'] as List<dynamic>?;
      final allowedBlockCards = _allowedBlockCards(actionType);
      final eligibleBlockers = _eligibleBlockers(
        actionType: actionType,
        actorId: actorId,
        targetId: targetId,
        alivePlayerIds: await _alivePlayerIdsInOrder(tx, roomId, game),
      );

      if (!eligibleBlockers.contains(playerId)) return;

      if (!block &&
          (actionType == 'assassinate' || actionType == 'coup') &&
          targetId == playerId &&
          revealedInfluence != null) {
        final targetData = playerStates[playerId];
        final influences =
            (targetData?['influences'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => e.toString())
                .toList();
        if (!influences.contains(revealedInfluence)) {
          return;
        }
      }

      if (block) {
        if (claimedCard == null || !allowedBlockCards.contains(claimedCard)) {
          return;
        }

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
        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'block_called',
          actorId: playerId,
          actionType: actionType,
          targetId: actorId,
          claimedCard: claimedCard,
        );
        tx.update(actionRef, {
          'eventLogs': actionEventLogs,
        });
        return;
      }

      final passes = (action['blockPasses'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toSet();
      if (!passes.contains(playerId)) {
        passes.add(playerId);
        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'block_pass',
          actorId: playerId,
          actionType: actionType,
        );
        tx.update(actionRef, {
          'blockPasses': passes.toList(),
          'eventLogs': actionEventLogs,
        });
      }

      if (passes.containsAll(eligibleBlockers)) {
        final forcedRevealByPlayerId = <String, String>{};
        if ((actionType == 'assassinate' || actionType == 'coup') &&
            targetId == playerId &&
            revealedInfluence != null) {
          forcedRevealByPlayerId[playerId] = revealedInfluence;
        }

        await _resolveActionSuccessInTransaction(
          tx,
          roomId: roomId,
          gameRef: gameRef,
          gameData: game,
          actionRef: actionRef,
          playerStates: playerStates,
          actionData: action,
          forcedRevealByPlayerId:
              forcedRevealByPlayerId.isEmpty ? null : forcedRevealByPlayerId,
          actionEventLogs: actionEventLogs,
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
      final game = await _getGameDataInPhase(tx, gameRef,
          expectedPhase: 'block_challenge');
      if (game == null) return;

      final actionId = game['currentActionId'] as String?;
      final blockId = game['currentBlockId'] as String?;
      if (actionId == null || blockId == null) return;

      final action = await _getActionData(tx, roomId, actionId);
      final blockData = await _getBlockData(tx, roomId, blockId);
      if (action == null || blockData == null) return;

      final actionRef = _actionsRef(roomId).doc(actionId);
      final blockRef = _blocksRef(roomId).doc(blockId);

      if ((blockData['status'] as String?) != 'pending') return;
      final playerStates = await _loadPlayerStatesInOrder(tx, roomId, game);
      final blockerId = blockData['blockerId'] as String;
      final responderData = playerStates[playerId];
      final responderAlive = (responderData?['alive'] as bool?) ?? false;
      if (!responderAlive) return;
      var actionEventLogs = action['eventLogs'] as List<dynamic>?;
      final challengePasses =
          (blockData['challengePasses'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toSet();

      if (challenge) {
        if (playerId == blockerId || challengePasses.contains(playerId)) return;
        final actionType = action['type'] as String? ?? 'income';

        final blockerRef = _playersRef(roomId).doc(blockerId);
        final challengerRef = _playersRef(roomId).doc(playerId);
        final blockerData = playerStates[blockerId];
        final challengerData = playerStates[playerId];
        if (blockerData == null || challengerData == null) return;

        final claimedCard = blockData['claimedCard'] as String?;
        final blockerHasCard = _playerHasCard(blockerData, claimedCard);

        final challengeRef = _challengesRef(roomId).doc();
        tx.set(challengeRef, {
          'actionId': actionId,
          'challengerId': playerId,
          'result': blockerHasCard ? 'fail' : 'success',
          'resolvedAt': FieldValue.serverTimestamp(),
        });

        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'block_challenge_called',
          actorId: playerId,
          actionType: actionType,
          targetId: blockerId,
        );

        if (blockerHasCard) {
          final shouldAwaitReveal = _shouldAwaitRevealSelection(
            challengerData,
            playerId: playerId,
          );
          if (shouldAwaitReveal) {
            _exchangeClaimedCardWithDeck(
              tx,
              roomId: roomId,
              gameRef: gameRef,
              gameData: game,
              playerRef: blockerRef,
              playerData: blockerData,
              claimedCard: claimedCard,
            );
            tx.update(actionRef, {
              'status': 'awaiting_reveal_selection',
              'revealChooserId': playerId,
              'revealSelectionReason':
                  _revealReasonBlockChallengeChallengerLost,
              'pendingBlockId': blockId,
              'eventLogs': actionEventLogs,
            });
            tx.update(gameRef, {'phase': 'resolve'});
            return;
          }

          final revealedCard = _loseOneInfluenceInTransaction(
            tx,
            challengerRef,
            challengerData,
            playerStates: playerStates,
            playerId: playerId,
          );
          if (revealedCard != null) {
            actionEventLogs = _appendActionEvent(
              actionEventLogs,
              eventType: 'influence_revealed',
              actorId: playerId,
              actionType: actionType,
              claimedCard: revealedCard,
            );
          }
          _exchangeClaimedCardWithDeck(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerRef: blockerRef,
            playerData: blockerData,
            claimedCard: claimedCard,
          );
          tx.update(blockRef, {'status': 'resolved'});
          tx.update(actionRef, {
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
            'eventLogs': actionEventLogs,
          });
          await _rotateTurnOrFinish(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            playerStates: playerStates,
          );
        } else {
          final shouldAwaitReveal = _shouldAwaitRevealSelection(
            blockerData,
            playerId: blockerId,
          );
          if (shouldAwaitReveal) {
            tx.update(actionRef, {
              'status': 'awaiting_reveal_selection',
              'revealChooserId': blockerId,
              'revealSelectionReason': _revealReasonBlockChallengeBlockerLost,
              'pendingBlockId': blockId,
              'eventLogs': actionEventLogs,
            });
            tx.update(gameRef, {'phase': 'resolve'});
            return;
          }

          final revealedCard = _loseOneInfluenceInTransaction(
            tx,
            blockerRef,
            blockerData,
            playerStates: playerStates,
            playerId: blockerId,
          );
          if (revealedCard != null) {
            actionEventLogs = _appendActionEvent(
              actionEventLogs,
              eventType: 'influence_revealed',
              actorId: blockerId,
              actionType: actionType,
              claimedCard: revealedCard,
            );
          }
          tx.update(actionRef, {'eventLogs': actionEventLogs});
          tx.update(blockRef, {'status': 'resolved'});
          await _resolveActionSuccessInTransaction(
            tx,
            roomId: roomId,
            gameRef: gameRef,
            gameData: game,
            actionRef: actionRef,
            playerStates: playerStates,
            actionData: action,
            actionEventLogs: actionEventLogs,
          );
        }

        return;
      }

      if (!challengePasses.contains(playerId)) {
        challengePasses.add(playerId);
        actionEventLogs = _appendActionEvent(
          actionEventLogs,
          eventType: 'block_challenge_pass',
          actorId: playerId,
          actionType: action['type'] as String? ?? 'income',
        );
        tx.update(blockRef, {'challengePasses': challengePasses.toList()});
        tx.update(actionRef, {
          'eventLogs': actionEventLogs,
        });
      }

      final alivePlayerIds = _alivePlayerIdsFromStates(playerStates, game);
      final neededPasses =
          alivePlayerIds.where((id) => id != blockerId).toSet();
      if (challengePasses.containsAll(neededPasses)) {
        tx.update(blockRef, {'status': 'resolved'});
        tx.update(actionRef, {
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
        await _rotateTurnOrFinish(
          tx,
          roomId: roomId,
          gameRef: gameRef,
          gameData: game,
          playerStates: playerStates,
        );
      }
    });
  }

  Future<void> processBots(String roomId) async {
    // Small delay so bot actions feel natural rather than instantaneous
    await Future.delayed(const Duration(milliseconds: 700));

    final room = await getRoom(roomId);
    if (room.roomState != GameState.playing) return;

    // --- Action phase: it is a bot's turn ---
    final bot = room.players.firstWhereOrNull(
        (p) => p.name == room.currentTurn && p.isBot && p.isAlive);

    if (room.phase == GamePhase.action && bot != null) {
      final action = _chooseBotAction(room, bot);
      CoupPlayerModel? target;
      if (CoupFunction.isNeedPlayerTarget(action)) {
        final targets =
            room.players.where((p) => p.isAlive && p.name != bot.name).toList();
        target = targets.isNotEmpty
            ? targets[_random.nextInt(targets.length)]
            : null;
      }
      await performAction(
        roomId,
        CoupActionModel(source: bot, actionType: action, target: target),
      );
      return;
    }

    final currentAction = room.currentAction;
    if (currentAction == null) return;

    if (room.phase == GamePhase.resolve &&
        currentAction.status == 'awaiting_reveal_selection') {
      final chooserPlayer = room.players.firstWhereOrNull(
          (player) => player.name == currentAction.revealChooserId);
      if (chooserPlayer != null &&
          (_isBotPlayerId(chooserPlayer.name) || chooserPlayer.isBot)) {
        final hiddenCards = chooserPlayer.cards
            .where((card) => !card.isRevealed)
            .toList(growable: false);
        if (hiddenCards.isNotEmpty) {
          await submitRevealSelection(
            roomId,
            chooserPlayer.name,
            revealedInfluence: hiddenCards.first.roleType.firestoreValue,
          );
        }
      }
      return;
    }

    if (room.phase == GamePhase.resolve &&
        currentAction.actionType == CoupActionType.ambassador &&
        currentAction.status == 'awaiting_exchange_selection') {
      final sourcePlayer = room.players.firstWhereOrNull(
          (player) => player.name == currentAction.source.name);
      if (sourcePlayer?.isBot ?? false) {
        final hiddenToKeep = currentAction.exchangeHiddenToKeep ?? 0;
        final defaultKeep =
            (currentAction.exchangeOriginalHidden ?? const <String>[])
                .take(hiddenToKeep)
                .toList(growable: false);
        await submitExchangeSelection(
          roomId,
          currentAction.source.name,
          keepInfluences: defaultKeep,
        );
      }
      return;
    }

    // --- Challenge phase: all pending bots respond in one pass ---
    // Intermediate passes only update the action doc (not the game doc), so the
    // room stream won't fire between bots — we must loop through all of them here.
    if (room.phase == GamePhase.challenge) {
      final pendingBots = room.players
          .where(
            (p) =>
                p.isBot &&
                p.isAlive &&
                p.name != currentAction.source.name &&
                !currentAction.listNeedVote.contains(p.name),
          )
          .toList();
      for (final bot in pendingBots) {
        final shouldChallenge = _random.nextInt(100) < 18;
        await respondToChallenge(roomId, bot.name, challenge: shouldChallenge);
        // A challenge resolves/transitions the action immediately; stop here and
        // let the stream drive the next state.
        if (shouldChallenge) break;
      }
      return;
    }

    // --- Block phase: all pending eligible bots respond in one pass ---
    if (room.phase == GamePhase.block) {
      final actionType = currentAction.actionType;
      final alreadyPassed = currentAction.listVoted;
      final pendingBlockers = room.players.where((p) {
        if (!p.isBot || !p.isAlive) return false;
        if (alreadyPassed.contains(p.name)) return false;
        if (actionType == CoupActionType.foreignAid) {
          return p.name != currentAction.source.name;
        }
        return p.name == currentAction.target?.name;
      }).toList();
      for (final blocker in pendingBlockers) {
        final willBlock = _random.nextInt(100) < 40;
        final cards = _allowedBlockCards(actionType.firestoreType);
        await respondToBlockOpportunity(
          roomId,
          blocker.name,
          block: willBlock,
          claimedCard: willBlock && cards.isNotEmpty ? cards.first : null,
        );
        // A block transitions to block_challenge phase; stop and let stream drive next state.
        if (willBlock) break;
      }
      return;
    }

    // --- Block-challenge phase: all pending bots respond in one pass ---
    if (room.phase == GamePhase.blockChallenge) {
      final gameDoc = await _games.doc(roomId).get();
      final blockId = gameDoc.data()?['currentBlockId'] as String?;
      if (blockId == null) return;

      final blockDoc = await _blocksRef(roomId).doc(blockId).get();
      if (!blockDoc.exists || blockDoc.data() == null) return;

      final blockData = blockDoc.data()!;
      final blockerId = blockData['blockerId'] as String?;
      final alreadyVoted =
          (blockData['challengePasses'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toSet();

      final pendingBots = room.players
          .where(
            (p) =>
                p.isBot &&
                p.isAlive &&
                p.name != blockerId &&
                !alreadyVoted.contains(p.name),
          )
          .toList();
      for (final bot in pendingBots) {
        final shouldChallenge = _random.nextInt(100) < 20;
        await respondToBlockChallenge(roomId, bot.name,
            challenge: shouldChallenge);
        // A challenge resolves the block; stop and let stream drive next state.
        if (shouldChallenge) break;
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
    required Map<String, Map<String, dynamic>> playerStates,
    required Map<String, dynamic> actionData,
    List<dynamic>? actionEventLogs,
    Map<String, String>? forcedRevealByPlayerId,
  }) async {
    final actionType = actionData['type'] as String;
    final sourceId = actionData['playerId'] as String;
    final targetId = actionData['targetId'] as String?;

    final sourceRef = _playersRef(roomId).doc(sourceId);
    final sourceData = playerStates[sourceId];
    final targetData = targetId == null ? null : playerStates[targetId];
    List<dynamic>? eventLogs = actionEventLogs;
    var isWaitingExchangeSelection = false;

    void appendEvent({
      required String eventType,
      required String actorId,
      required String actionType,
      String? targetId,
      String? claimedCard,
      int? coinDelta,
    }) {
      eventLogs = _appendActionEvent(
        eventLogs,
        eventType: eventType,
        actorId: actorId,
        actionType: actionType,
        targetId: targetId,
        claimedCard: claimedCard,
        coinDelta: coinDelta,
      );
    }

    switch (actionType) {
      case 'income':
        eventLogs = _updatePlayerCoins(
          tx,
          sourceRef,
          sourceId,
          actionType,
          1,
          eventLogs,
        );
        break;
      case 'foreign_aid':
        eventLogs = _updatePlayerCoins(
          tx,
          sourceRef,
          sourceId,
          actionType,
          2,
          eventLogs,
        );
        break;
      case 'tax':
        eventLogs = _updatePlayerCoins(
          tx,
          sourceRef,
          sourceId,
          actionType,
          3,
          eventLogs,
        );
        break;
      case 'steal':
        if (targetId != null && targetData != null) {
          final targetRef = _playersRef(roomId).doc(targetId);
          final transfer = _applySteal(tx, sourceRef, targetRef, targetData);
          if (transfer > 0) {
            appendEvent(
              eventType: 'coins_changed',
              actorId: sourceId,
              actionType: actionType,
              targetId: targetId,
              coinDelta: transfer,
            );
            appendEvent(
              eventType: 'coins_changed',
              actorId: targetId,
              actionType: actionType,
              targetId: sourceId,
              coinDelta: -transfer,
            );
          }
        }
        break;
      case 'assassinate':
        if (targetId != null && targetData != null) {
          final targetRef = _playersRef(roomId).doc(targetId);
          final revealedCard = _loseOneInfluenceInTransaction(
            tx,
            targetRef,
            targetData,
            playerStates: playerStates,
            playerId: targetId,
            preferredInfluence: forcedRevealByPlayerId?[targetId],
          );
          if (revealedCard != null) {
            appendEvent(
              eventType: 'influence_revealed',
              actorId: targetId,
              actionType: actionType,
              claimedCard: revealedCard,
            );
          }
        }
        break;
      case 'coup':
        if (targetId != null && targetData != null) {
          final targetRef = _playersRef(roomId).doc(targetId);
          final revealedCard = _loseOneInfluenceInTransaction(
            tx,
            targetRef,
            targetData,
            playerStates: playerStates,
            playerId: targetId,
            preferredInfluence: forcedRevealByPlayerId?[targetId],
          );
          if (revealedCard != null) {
            appendEvent(
              eventType: 'influence_revealed',
              actorId: targetId,
              actionType: actionType,
              claimedCard: revealedCard,
            );
          }
        }
        break;
      case 'exchange':
        if (sourceData != null) {
          final existingPool =
              (actionData['exchangePool'] as List<dynamic>? ?? <dynamic>[])
                  .map((e) => e.toString())
                  .toList(growable: false);
          final exchangeKeepInfluences =
              (actionData['exchangeKeepInfluences'] as List<dynamic>? ??
                      <dynamic>[])
                  .map((e) => e.toString())
                  .toList(growable: false);
          if (exchangeKeepInfluences.isEmpty) {
            if (existingPool.isNotEmpty) {
              throw Exception('Please choose cards to keep');
            }
            final prepared = _prepareExchangeSelection(
              gameData: gameData,
              sourceData: sourceData,
            );
            if (prepared != null) {
              tx.update(actionRef, {
                'status': 'awaiting_exchange_selection',
                'exchangePool': prepared.pool,
                'exchangeOriginalHidden': prepared.originalHidden,
                'exchangeHiddenToKeep': prepared.hiddenToKeep,
                'eventLogs': eventLogs,
              });
              tx.update(gameRef, {
                'phase': 'resolve',
                'currentActionId': actionRef.id,
                'currentBlockId': null,
                'deck': prepared.deckAfterDraw,
              });
              isWaitingExchangeSelection = true;
            }
          } else {
            final hiddenToKeepRaw = actionData['exchangeHiddenToKeep'];
            final hiddenToKeep = hiddenToKeepRaw is int
                ? hiddenToKeepRaw
                : (hiddenToKeepRaw is num ? hiddenToKeepRaw.toInt() : null);

            if (existingPool.isEmpty || hiddenToKeep == null) {
              throw Exception('Exchange selection data is missing');
            }

            final applied = _applyExchangeSelection(
              tx,
              gameRef: gameRef,
              sourceRef: sourceRef,
              gameData: gameData,
              sourceData: sourceData,
              pool: existingPool,
              hiddenToKeep: hiddenToKeep,
              selectedKeep: exchangeKeepInfluences,
            );
            if (!applied) {
              throw Exception('Invalid exchange selection');
            }
          }
        }
        break;
      default:
        break;
    }

    if (isWaitingExchangeSelection) {
      return;
    }

    tx.update(actionRef, {
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'eventLogs': eventLogs,
    });

    await _rotateTurnOrFinish(
      tx,
      roomId: roomId,
      gameRef: gameRef,
      gameData: gameData,
      playerStates: playerStates,
    );
  }

  int _applySteal(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> sourceRef,
    DocumentReference<Map<String, dynamic>> targetRef,
    Map<String, dynamic> targetData,
  ) {
    final targetCoins = (targetData['coins'] as int?) ?? 0;
    final transfer = targetCoins >= 2 ? 2 : targetCoins;
    if (transfer <= 0) return 0;

    tx.update(targetRef, {'coins': targetCoins - transfer});
    tx.update(sourceRef, {'coins': FieldValue.increment(transfer)});
    return transfer;
  }

  List<dynamic>? _updatePlayerCoins(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> playerRef,
    String playerId,
    String actionType,
    int delta,
    List<dynamic>? eventLogs,
  ) {
    tx.update(playerRef, {'coins': FieldValue.increment(delta)});
    return _appendActionEvent(
      eventLogs,
      eventType: 'coins_changed',
      actorId: playerId,
      actionType: actionType,
      coinDelta: delta,
    );
  }

  _PreparedExchangeSelection? _prepareExchangeSelection({
    required Map<String, dynamic> gameData,
    required Map<String, dynamic> sourceData,
  }) {
    final deck = (gameData['deck'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    if (deck.length < 2) return null;

    final influences =
        (sourceData['influences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final revealed =
        (sourceData['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();

    // A player can never hold more than 2 total influences (hidden + revealed).
    final hiddenToKeep = (2 - revealed.length).clamp(0, 2);
    if (hiddenToKeep == 0) return null;

    final drawA = deck.removeLast();
    final drawB = deck.removeLast();
    final pool = <String>[...influences, drawA, drawB];

    return _PreparedExchangeSelection(
      pool: pool,
      originalHidden: influences,
      hiddenToKeep: hiddenToKeep,
      deckAfterDraw: deck,
    );
  }

  bool _applyExchangeSelection(
    Transaction tx, {
    required DocumentReference<Map<String, dynamic>> gameRef,
    required DocumentReference<Map<String, dynamic>> sourceRef,
    required Map<String, dynamic> gameData,
    required Map<String, dynamic> sourceData,
    required List<String> pool,
    required int hiddenToKeep,
    required List<String> selectedKeep,
  }) {
    final normalizedKeep = selectedKeep
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (!_isValidExchangeKeepSelection(
      normalizedKeep,
      pool: pool,
      hiddenToKeep: hiddenToKeep,
    )) {
      return false;
    }

    final deck = (gameData['deck'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final revealed =
        (sourceData['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();

    final returns = List<String>.from(pool);
    for (final kept in normalizedKeep) {
      final index = returns.indexOf(kept);
      if (index >= 0) {
        returns.removeAt(index);
      }
    }
    deck.addAll(returns);
    deck.shuffle(_random);

    tx.update(sourceRef, {
      'influences': normalizedKeep,
      'revealedInfluences': revealed,
    });
    tx.update(gameRef, {'deck': deck});
    return true;
  }

  bool _isValidExchangeKeepSelection(
    List<String> selectedKeep, {
    required List<String> pool,
    required int hiddenToKeep,
  }) {
    if (selectedKeep.length != hiddenToKeep) return false;

    final poolCounts = <String, int>{};
    for (final card in pool) {
      poolCounts[card] = (poolCounts[card] ?? 0) + 1;
    }

    for (final selected in selectedKeep) {
      final remain = poolCounts[selected] ?? 0;
      if (remain <= 0) return false;
      poolCounts[selected] = remain - 1;
    }

    return true;
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
    Map<String, Map<String, dynamic>>? playerStates,
  }) async {
    final order = (gameData['playerOrder'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    if (order.isEmpty) return;

    final alive = playerStates != null
        ? _alivePlayerIdsFromStates(playerStates, gameData)
        : await _alivePlayerIdsInOrder(tx, roomId, gameData);
    if (alive.length <= 1) {
      final hostId = gameData['hostId'] as String?;
      final playerIdsToResetReady =
          playerStates?.keys.toList(growable: false) ?? order;
      for (final playerId in playerIdsToResetReady) {
        final playerData = playerStates?[playerId];
        final isBot = (playerData?['isBot'] as bool?) ?? false;
        final isHost = hostId != null && playerId == hostId;
        tx.update(
            _playersRef(roomId).doc(playerId), {'isReady': isBot || isHost});
      }

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

  Future<Map<String, Map<String, dynamic>>> _loadPlayerStatesInOrder(
    Transaction tx,
    String roomId,
    Map<String, dynamic> game,
  ) async {
    final order = (game['playerOrder'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    final playerStates = <String, Map<String, dynamic>>{};
    for (final playerId in order) {
      final playerSnap = await tx.get(_playersRef(roomId).doc(playerId));
      if (!playerSnap.exists || playerSnap.data() == null) continue;
      playerStates[playerId] = playerSnap.data()!;
    }
    return playerStates;
  }

  List<String> _alivePlayerIdsFromStates(
    Map<String, Map<String, dynamic>> playerStates,
    Map<String, dynamic> game,
  ) {
    final order = (game['playerOrder'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    return order
        .where(
            (playerId) => (playerStates[playerId]?['alive'] as bool?) ?? false)
        .toList();
  }

  String? _loseOneInfluenceInTransaction(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> playerRef,
    Map<String, dynamic> playerData, {
    Map<String, Map<String, dynamic>>? playerStates,
    String? playerId,
    String? preferredInfluence,
  }) {
    final influences =
        (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final revealed =
        (playerData['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();

    if (influences.isEmpty) {
      tx.update(playerRef, {'alive': false});
      if (playerStates != null && playerId != null) {
        final updatedData = Map<String, dynamic>.from(playerData);
        updatedData['alive'] = false;
        updatedData['influences'] = <String>[];
        playerStates[playerId] = updatedData;
      }
      return null;
    }

    final preferredIndex = preferredInfluence == null
        ? -1
        : influences.indexOf(preferredInfluence);
    final lost = preferredIndex >= 0
        ? influences.removeAt(preferredIndex)
        : influences.removeAt(0);
    revealed.add(lost);

    tx.update(playerRef, {
      'influences': influences,
      'revealedInfluences': revealed,
      'alive': influences.isNotEmpty,
    });

    if (playerStates != null && playerId != null) {
      final updatedData = Map<String, dynamic>.from(playerData);
      updatedData['influences'] = influences;
      updatedData['revealedInfluences'] = revealed;
      updatedData['alive'] = influences.isNotEmpty;
      playerStates[playerId] = updatedData;
    }

    return lost;
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

    final influences =
        (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final index = influences.indexOf(claimedCard);
    if (index == -1) return;

    final deck = (gameData['deck'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
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
    final influences =
        (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
    return influences.contains(claimedCard);
  }

  bool _shouldAwaitRevealSelection(
    Map<String, dynamic> playerData, {
    required String playerId,
  }) {
    final influences =
        (playerData['influences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList(growable: false);
    final isBot =
        _isBotPlayerId(playerId) || ((playerData['isBot'] as bool?) ?? false);
    return !isBot && influences.isNotEmpty;
  }

  bool _isBotPlayerId(String playerId) {
    return playerId.startsWith('BOT_');
  }

  bool _isActionBlockable(String actionType) {
    return actionType == 'foreign_aid' ||
        actionType == 'assassinate' ||
        actionType == 'steal';
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

    if (actionType == 'assassinate' ||
        actionType == 'steal' ||
        actionType == 'coup') {
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

  CoupPlayerModel _playerFromFirestore(
      String playerId, Map<String, dynamic> data) {
    final influences = (data['influences'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final revealed =
        (data['revealedInfluences'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();

    final cards = <CoupCardModel>[
      ...influences.map((v) => CoupCardModel(
          roleType: CoupRoleTypeX.fromFirestoreValue(v), isRevealed: false)),
      ...revealed.map((v) => CoupCardModel(
          roleType: CoupRoleTypeX.fromFirestoreValue(v), isRevealed: true)),
    ];

    return CoupPlayerModel(
      name: playerId,
      displayName: data['displayName'] as String?,
      isReady: (data['isReady'] as bool?) ?? true,
      cards: cards,
      isAlive: (data['alive'] as bool?) ?? true,
      coins: (data['coins'] as int?) ?? 2,
      isBot: (data['isBot'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> _playerToFirestore(CoupPlayerModel player) {
    final influences = player.cards
        .where((e) => !e.isRevealed)
        .map((e) => e.roleType.firestoreValue)
        .toList();
    final revealed = player.cards
        .where((e) => e.isRevealed)
        .map((e) => e.roleType.firestoreValue)
        .toList();

    return {
      'name': player.name,
      'displayName': player.displayName,
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
        CoupPlayerModel(
            name: sourceId,
            isReady: true,
            cards: const [],
            isAlive: true,
            coins: 0);
    final target = targetId == null
        ? null
        : players.firstWhereOrNull((p) => p.name == targetId);

    final challengePasses =
        (action['challengePasses'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final blockPasses = (action['blockPasses'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();

    return CoupActionModel(
      actionId: actionId,
      source: source,
      target: target,
      actionType: CoupActionTypeX.fromFirestoreType(
          (action['type'] as String?) ?? 'income'),
      status: action['status'] as String?,
      claimedCard: action['claimedCard'] as String?,
      blockerId: action['blockerId'] as String?,
      blockClaimedCard: action['blockClaimedCard'] as String?,
      revealChooserId: action['revealChooserId'] as String?,
      revealSelectionReason: action['revealSelectionReason'] as String?,
      pendingBlockId: action['pendingBlockId'] as String?,
    )
      ..listNeedVote = challengePasses
      ..listVoted = blockPasses
      ..exchangePool = (action['exchangePool'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false)
      ..exchangeOriginalHidden =
          (action['exchangeOriginalHidden'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toList(growable: false)
      ..exchangeHiddenToKeep =
          (action['exchangeHiddenToKeep'] as num?)?.toInt();
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

class _PreparedExchangeSelection {
  final List<String> pool;
  final List<String> originalHidden;
  final int hiddenToKeep;
  final List<String> deckAfterDraw;

  const _PreparedExchangeSelection({
    required this.pool,
    required this.originalHidden,
    required this.hiddenToKeep,
    required this.deckAfterDraw,
  });
}
