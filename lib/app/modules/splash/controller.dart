import 'dart:async';

import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  bool _hasNavigated = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      if (user == null) {
        final credential = await auth.signInAnonymously().timeout(const Duration(seconds: 8));
        user = credential.user;
      }

      Get.log('Splash auth ready: ${user?.uid ?? 'anonymous-unavailable'}');
    } catch (e) {
      Get.log('Splash bootstrap failed: $e');
    }

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _goHome();
  }

  void _goHome() {
    if (_hasNavigated || isClosed) return;
    _hasNavigated = true;
    Get.offNamed(AppRoutes.home);
  }
}
