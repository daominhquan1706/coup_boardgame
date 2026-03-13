import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:coup_boardgame/app/translations/en_us.dart';
import 'package:coup_boardgame/app/translations/vi_vn.dart';

class AppTranslationKey {
  AppTranslationKey._();

  // API Error
  static String get unknownError => "unknownError".tr;
  static String get timeoutError => "timeoutError".tr;
  static String get noConnectionError => "noConnectionError".tr;
  static String get unauthorizedError => "unauthorizedError".tr;
  static String get tryAgain => "tryAgain".tr;
  static String get identify => "identify".tr;
  static String get error => "error".tr;
  static String get successful => "successful".tr;
  static String get notMatch => "notMatch".tr;
  static String get noEmpty => "noEmpty".tr;
  static String get noRecords => "noRecords".tr;
  static String get pleaseLogin => "pleaseLogin".tr;
  static String get noData => "noData".tr;
  static String get enterText => "enterText".tr;

  // Game end screen
  static String get gameVictory => "gameVictory".tr;
  static String get gameDefeated => "gameDefeated".tr;
  static String get gameYouWon => "gameYouWon".tr;
  static String get gameRanking => "gameRanking".tr;
  static String get gameSummary => "gameSummary".tr;
  static String get gameMostBluffs => "gameMostBluffs".tr;
  static String get gameTotalCoups => "gameTotalCoups".tr;
  static String get gamePlayAgain => "gamePlayAgain".tr;
  static String get gameExit => "gameExit".tr;
}

class AppTranslation {
  AppTranslation._();

  static Locale get locale {
    final device = Get.deviceLocale;
    final code = device?.languageCode;
    if (code == 'vi') return const Locale('vi');
    return const Locale('en');
  }

  static final Map<String, Map<String, String>> translations = {
    'en': enUS,
    'vi': viVN,
  };
}
