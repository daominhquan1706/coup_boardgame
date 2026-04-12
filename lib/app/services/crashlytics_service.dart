import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';

class CrashlyticsService extends GetxService {
  static CrashlyticsService get to => Get.find<CrashlyticsService>();

  final FirebaseCrashlytics? _crashlytics = !kIsWeb ? FirebaseCrashlytics.instance : null;

  void log(String message) {
    _crashlytics?.log(message);
    Get.log('Crashlytics Log: $message');
  }

  void recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) {
    _crashlytics?.recordError(exception, stack, reason: reason, fatal: fatal);
    if (kIsWeb) {
      Get.log('Web Crashlytics mocked Error: $exception, Reason: $reason');
    }
  }

  void forceCrash() {
    _crashlytics?.crash();
  }
}
