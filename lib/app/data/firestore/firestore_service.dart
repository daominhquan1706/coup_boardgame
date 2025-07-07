import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_room_model.dart';
import 'package:coup_boardgame/app/utils/constants.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for room data to reduce reads
  final Map<String, CoupRoomModel> _roomCache = {};
  final Map<String, Timer> _cacheTimers = {};
  
  @override
  void onInit() {
    super.onInit();
    // Enable offline persistence for better performance
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<bool> createRoom(String roomId, List<String> players) async {
    try {
      final newRoom = CoupRoomModel(
        roomId: roomId,
        players: [],
        roomState: GameState.waiting,
        deck: [],
      );

      await _firestore.collection('rooms').doc(roomId).set(newRoom.toJson());
      
      // Update cache
      _updateCache(roomId, newRoom);
      
      Get.log('Room created successfully');
      return true;
    } catch (e) {
      Get.log('Failed to create room: $e');
      return false;
    }
  }

  // Optimized get room with caching
  Future<CoupRoomModel> getRoom(String roomId) async {
    // Check cache first
    if (_roomCache.containsKey(roomId)) {
      return _roomCache[roomId]!;
    }
    
    final room = await _firestore.collection('rooms').doc(roomId).get();

    if (room.exists == false) {
      throw UnknownError();
    }

    final roomModel = CoupRoomModel.fromJson(room.data()!);
    _updateCache(roomId, roomModel);
    return roomModel;
  }

  Stream<CoupRoomModel> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((event) {
      final roomModel = CoupRoomModel.fromJson(event.data()!);
      _updateCache(roomId, roomModel);
      return roomModel;
    });
  }

  // OPTIMIZED: Use transaction for atomic operations
  Future<bool> joinRoom(String roomId, CoupPlayerModel player) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);
        
        if (!roomDoc.exists) {
          throw JoinRoomError('Room not found');
        }
        
        final roomData = CoupRoomModel.fromJson(roomDoc.data()!);
        final players = List<CoupPlayerModel>.from(roomData.players);
        
        // Validation
        if (players.length >= Constant.maxPlayersPerRoom) {
          throw JoinRoomError('Room is full');
        }
        
        if (players.any((element) => element.name == player.name)) {
          players.removeWhere((element) => element.name == player.name);
        }
        
        players.add(player);
        
        transaction.update(roomRef, {
          'players': players.map((e) => e.toJson()).toList(),
        });
        
        // Update cache
        final updatedRoom = roomData.copyWith(players: players);
        _updateCache(roomId, updatedRoom);
        
        return true;
      });
    } catch (e) {
      Get.log('Failed to add player to room: $e');
      if (e is JoinRoomError) rethrow;
      return false;
    }
  }

  // OPTIMIZED: Batch validation check
  Future<bool> isCanJoinRoom(String roomId, String userName) async {
    try {
      final room = await getRoom(roomId); // Uses cache
      
      if (room.players.length >= Constant.maxPlayersPerRoom) {
        throw JoinRoomError('Room is full');
      }
      
      if (room.players.any((element) => element.name == userName)) {
        throw JoinRoomError('Name is already exist');
      }
      
      return true;
    } catch (e) {
      if (e is JoinRoomError) rethrow;
      throw JoinRoomError('Room not found');
    }
  }

  // OPTIMIZED: Use cached data
  Future<CoupPlayerModel> getPlayer(String roomId, String userName) async {
    final room = await getRoom(roomId);
    
    final player = room.players.firstWhereOrNull(
      (element) => element.name == userName,
    );
    
    if (player == null) {
      throw UnknownError();
    }
    
    return player;
  }

  // OPTIMIZED: Use batch operations for better performance
  Future<void> startGame(String roomId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomDoc = await transaction.get(roomRef);
        
        if (!roomDoc.exists) throw UnknownError();
        
        final room = CoupRoomModel.fromJson(roomDoc.data()!);
        final listCards = CoupFunction.generateDeck(room.players.length);
        
        final players = room.players.map((player) {
          return player.copyWith(
            cards: [listCards.removeLast(), listCards.removeLast()],
            isReady: false,
            isAlive: true,
            coins: 2,
          );
        }).toList();

        final pickRandomPlayer = _pickRandom(players);
        
        final updatedRoom = room.copyWith(
          deck: listCards,
          players: players,
          roomState: GameState.playing,
          currentTurn: pickRandomPlayer.name,
        );
        
        transaction.update(roomRef, updatedRoom.toJson());
        
        // Update cache
        _updateCache(roomId, updatedRoom);
      });
    } catch (e) {
      Get.log('Failed to start game: $e');
      rethrow;
    }
  }

  // OPTIMIZED: Use transaction for atomic updates
  Future<void> endGame(String roomId) async {
    await _firestore.runTransaction((transaction) async {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final roomDoc = await transaction.get(roomRef);
      
      if (!roomDoc.exists) throw UnknownError();
      
      final room = CoupRoomModel.fromJson(roomDoc.data()!);
      
      final players = room.players.map((player) {
        return player.copyWith(
          cards: [],
          isAlive: true,
          coins: 2,
        );
      }).toList();

      final updatedRoom = room.copyWith(
        roomState: GameState.waiting,
        players: players,
        deck: [],
      );
      
      transaction.update(roomRef, updatedRoom.toJson());
      
      // Update cache
      _updateCache(roomId, updatedRoom);
    });
  }

  // OPTIMIZED: Batch operations for better performance
  Future<void> performAction(String roomCode, CoupActionModel actionModel) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomCode);
        final roomDoc = await transaction.get(roomRef);
        
        if (!roomDoc.exists) throw UnknownError();
        
        final room = CoupRoomModel.fromJson(roomDoc.data()!);
        
        switch (actionModel.actionType) {
          case CoupActionType.income:
            _performIncomeTransaction(transaction, roomRef, room, actionModel);
            break;
          case CoupActionType.foreignAid:
            _performForeignAidTransaction(transaction, roomRef, room, actionModel);
            break;
          case CoupActionType.taxByDuke:
            _performTaxTransaction(transaction, roomRef, room, actionModel);
            break;
          case CoupActionType.exchangeByAmbassador:
            _performExchangeTransaction(transaction, roomRef, room, actionModel);
            break;
          default:
            // Handle other actions
            break;
        }
      });
    } catch (e) {
      Get.log('Failed to perform action: $e');
      rethrow;
    }
  }

  void _performIncomeTransaction(
    Transaction transaction,
    DocumentReference roomRef,
    CoupRoomModel room,
    CoupActionModel action,
  ) {
    final players = List<CoupPlayerModel>.from(room.players);
    final playerIndex = players.indexWhere((p) => p.name == action.source.name);
    
    if (playerIndex != -1) {
      players[playerIndex] = players[playerIndex].copyWith(
        coins: players[playerIndex].coins + 1,
      );
      
      transaction.update(roomRef, {
        'players': players.map((e) => e.toJson()).toList(),
      });
    }
  }

  void _performForeignAidTransaction(
    Transaction transaction,
    DocumentReference roomRef,
    CoupRoomModel room,
    CoupActionModel action,
  ) {
    final players = List<CoupPlayerModel>.from(room.players);
    final playerIndex = players.indexWhere((p) => p.name == action.source.name);
    
    if (playerIndex != -1) {
      players[playerIndex] = players[playerIndex].copyWith(
        coins: players[playerIndex].coins + 2,
      );
      
      transaction.update(roomRef, {
        'players': players.map((e) => e.toJson()).toList(),
      });
    }
  }

  void _performTaxTransaction(
    Transaction transaction,
    DocumentReference roomRef,
    CoupRoomModel room,
    CoupActionModel action,
  ) {
    final players = List<CoupPlayerModel>.from(room.players);
    final playerIndex = players.indexWhere((p) => p.name == action.source.name);
    
    if (playerIndex != -1) {
      players[playerIndex] = players[playerIndex].copyWith(
        coins: players[playerIndex].coins + 3,
      );
      
      transaction.update(roomRef, {
        'players': players.map((e) => e.toJson()).toList(),
      });
    }
  }

  void _performExchangeTransaction(
    Transaction transaction,
    DocumentReference roomRef,
    CoupRoomModel room,
    CoupActionModel action,
  ) {
    final players = List<CoupPlayerModel>.from(room.players);
    final playerIndex = players.indexWhere((p) => p.name == action.source.name);
    final deck = List.from(room.deck);
    
    if (playerIndex != -1 && deck.length >= 2) {
      final player = players[playerIndex];
      final newCards = [
        ...player.cards,
        deck.removeLast(),
        deck.removeLast(),
      ];
      
      players[playerIndex] = player.copyWith(cards: newCards);
      
      transaction.update(roomRef, {
        'players': players.map((e) => e.toJson()).toList(),
        'deck': deck.map((e) => e.toJson()).toList(),
      });
    }
  }

  // Cache management
  void _updateCache(String roomId, CoupRoomModel room) {
    _roomCache[roomId] = room;
    
    // Clear cache after 5 minutes
    _cacheTimers[roomId]?.cancel();
    _cacheTimers[roomId] = Timer(const Duration(minutes: 5), () {
      _roomCache.remove(roomId);
      _cacheTimers.remove(roomId);
    });
  }

  void clearCache() {
    _roomCache.clear();
    _cacheTimers.forEach((_, timer) => timer.cancel());
    _cacheTimers.clear();
  }

  CoupPlayerModel _pickRandom(List<CoupPlayerModel> players) {
    final random = Random();
    final index = random.nextInt(players.length);
    return players[index];
  }

  @override
  void onClose() {
    clearCache();
    super.onClose();
  }
}
