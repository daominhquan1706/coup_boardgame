import 'package:coup_boardgame/app/modules/splash/binding.dart';
import 'package:get/get.dart';
import 'package:coup_boardgame/app/modules/game/binding.dart';
import 'package:coup_boardgame/app/modules/game/page.dart';
import 'package:coup_boardgame/app/modules/lobby_room/binding.dart';
import 'package:coup_boardgame/app/modules/lobby_room/page.dart';
import 'package:coup_boardgame/app/modules/home/binding.dart';
import 'package:coup_boardgame/app/modules/home/page.dart';
import 'package:coup_boardgame/app/modules/home/binding.dart';
import 'package:coup_boardgame/app/modules/home/page.dart';
import 'package:coup_boardgame/app/modules/splash/page.dart';
part './app_routes.dart';

class AppPages {
  AppPages._();
  static final pages = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.lobbyRoom,
      page: () => const LobbyRoomPage(),
      binding: LobbyRoomBinding(),
    ),
    GetPage(
      name: AppRoutes.gameStart,
      page: () => const GamePage(),
      binding: GameStartBinding(),
    ),
  ];
}
