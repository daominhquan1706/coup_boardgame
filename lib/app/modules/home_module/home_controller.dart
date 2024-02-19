import 'dart:math';

import 'package:coup_boardgame/app/data/api/api_error.dart';
import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../app/data/provider/home_provider.dart';

class HomeController extends GetxController {
  final HomeProvider? provider;
  HomeController({this.provider});

  // text field controller for name input
  final Rx<String> name = ''.obs;
  final Rx<String> roomCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // FirebaseAuth.instance.signInAnonymously().then((value) {
    //   Get.log('User ID: ${value.user!.uid}');
    // });
  }

  Future<void> onTapCreateRoom() async {
    if (name.value.isEmpty) {
      // close old snackbar

      EasyLoading.showInfo('Please enter your name');
      return;
    }

    EasyLoading.show(status: 'Creating room...');

    final roomCode = generateRoomCode();
    try {
      final isCreateRoomeSuccess =
          await Get.find<FirestoreService>().createRoom(roomCode, [name.value]);

      EasyLoading.dismiss();
      if (isCreateRoomeSuccess) {
        Get.toNamed(AppRoutes.lobbyRoom, parameters: {
          'userName': name.value,
          'roomCode': roomCode,
        });
      } else {
        EasyLoading.showError('Failed to create room');
      }
    } catch (e) {
      EasyLoading.showError('Failed to create room');
    }
  }

  String generateRoomCode() {
    //generate random room code have 4 numbers

    final random = Random();
    final code = random.nextInt(9999);
    return code.toString().padLeft(4, '0');
  }

  Future<void> onTapJoinRoom() async {
    //check name , room code
    if (name.value.isEmpty) {
      EasyLoading.showInfo('Please enter your name');
      return;
    }

    if (roomCode.value.isEmpty) {
      EasyLoading.showInfo('Please enter room code');
      return;
    }
    try {
      final isCanJoinRoom =
          await Get.find<FirestoreService>().isCanJoinRoom(roomCode.value, name.value);
      if (isCanJoinRoom) {
        Get.toNamed(AppRoutes.lobbyRoom, parameters: {
          'userName': name.value,
          'roomCode': roomCode.value,
        });
      }
    } on JoinRoomError catch (e) {
      EasyLoading.showError(e.message);
    } catch (e) {
      EasyLoading.showError('Failed to join room');
    }
  }
}
