import 'dart:async';

import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        // sign in anonymously
        await FirebaseAuth.instance.signInAnonymously();

        // Get.offNamed(AppRoutes.login);
      }
      Get.offNamed(AppRoutes.home);
    });

    ///Your Function in the Future
    Future.delayed(const Duration(seconds: 2), () {
      // 2s over, navigate to a new page
      Get.offNamed(AppRoutes.home);
    });
  }
}
