import 'package:get/get.dart';
import 'package:coup_boardgame/app/modules/home_module/home_binding.dart';
import 'package:coup_boardgame/app/modules/home_module/home_page.dart';
import 'package:coup_boardgame/app/modules/home_module/home_binding.dart';
import 'package:coup_boardgame/app/modules/home_module/home_page.dart';
import 'package:coup_boardgame/app/modules/splash_module/splash_page.dart';
part './app_routes.dart';

class AppPages {
  AppPages._();
  static final pages = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashPage(),
    ),
    GetPage(
        name: AppRoutes.home,
        page: () => const HomePage(),
        binding: HomeBinding(),
    ),
  ];
}
