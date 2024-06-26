import 'package:get/get.dart';

import '../../data/provider/game_provider.dart';
import 'controller.dart';

class GameStartBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GameStartController>(
      () => GameStartController(
        provider: GameProvider(),
      ),
    );
  }
}
