import 'dart:math';

import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/services/crashlytics_service.dart';
import 'package:coup_boardgame/app/constants/local_storage_keys.dart';
import 'package:coup_boardgame/app/utils/widgets/app_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/provider/home_provider.dart';

class HomeController extends GetxController {
  final HomeProvider? provider;
  HomeController({this.provider});

  final Rx<String> roomCode = ''.obs;
  final Rx<String> selectedLanguage = 'en'.obs;
  final GetStorage _storage = GetStorage();
  late final String playerId;
  late final String defaultDisplayName;

  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value = Get.locale?.languageCode == 'vi' ? 'vi' : 'en';
    playerId =
        _storage.read<String>(LocalStorageKeys.userName) ?? _generatePlayerId();
    _storage.write(LocalStorageKeys.userName, playerId);

    defaultDisplayName = _storage.read<String>(LocalStorageKeys.displayName) ??
        'Player ${playerId.substring(playerId.length - 4)}';
    _storage.write(LocalStorageKeys.displayName, defaultDisplayName);
  }

  @override
  void onReady() {
    super.onReady();
    if (_storage.read('has_crashed_once') != true) {
      _storage.write('has_crashed_once', true);
      Future.delayed(const Duration(seconds: 4), () {
        Get.log('Triggering auto-crash for testing...');
        CrashlyticsService.to.forceCrash();
      });
    }
  }

  void changeLanguage(String languageCode) {
    if (selectedLanguage.value == languageCode) return;
    selectedLanguage.value = languageCode;
    Get.updateLocale(Locale(languageCode));
  }

  Future<void> onTapCreateRoom() async {
    AppToast.info('msgCreatingRoom'.tr);

    final roomCode = generateRoomCode();
    try {
      final isCreateRoomeSuccess =
          await Get.find<FirestoreService>().createRoom(
        roomCode,
        [playerId],
        hostDisplayName: defaultDisplayName,
      );

      if (isCreateRoomeSuccess) {
        Get.toNamed(AppRoutes.lobbyRoomPath(roomCode));
      } else {
        AppToast.error('msgFailedCreateRoom'.tr);
      }
    } catch (e, stack) {
      CrashlyticsService.to.recordError(e, stack, reason: 'Failed to create room');
      AppToast.error('msgFailedCreateRoom'.tr);
    }
  }

  String generateRoomCode() {
    //generate random room code have 4 numbers

    final random = Random();
    final code = random.nextInt(9999);
    return code.toString().padLeft(4, '0');
  }

  Future<void> onTapJoinRoom() async {
    final enteredRoomCode = roomCode.value.trim();

    if (enteredRoomCode.isEmpty) {
      AppToast.info('msgEnterRoomCode'.tr);
      return;
    }

    try {
      final isCanJoinRoom = await Get.find<FirestoreService>()
          .isCanJoinRoom(enteredRoomCode, playerId);
      if (isCanJoinRoom) {
        Get.toNamed(AppRoutes.lobbyRoomPath(enteredRoomCode));
      } else {
        AppToast.error('msgRoomNotFound'.tr);
      }
    } on JoinRoomError catch (e, stack) {
      CrashlyticsService.to.recordError(e, stack, reason: 'Join room error');
      AppToast.error(_joinRoomErrorMessage(e.message).tr);
    } catch (e, stack) {
      CrashlyticsService.to.recordError(e, stack, reason: 'Failed to join room');
      AppToast.error('msgFailedJoinRoom'.tr);
    }
  }

  String _joinRoomErrorMessage(String message) {
    switch (message) {
      case 'Room not found':
        return 'msgRoomNotFound';
      case 'Room is full':
        return 'msgRoomIsFull';
      case 'Game already started':
        return 'msgGameAlreadyStarted';
      default:
        return 'msgFailedJoinRoom';
    }
  }

  String _generatePlayerId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      final suffix = uid.substring(uid.length > 8 ? uid.length - 8 : 0);
      return 'P_$suffix';
    }

    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'P_$seed';
  }
}
