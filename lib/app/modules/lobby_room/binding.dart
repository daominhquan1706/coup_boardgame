import 'package:get/get.dart';

import '../../data/provider/lobby_room_provider.dart';
import 'controller.dart';

class LobbyRoomBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LobbyRoomController>(
      () => LobbyRoomController(
        provider: LobbyRoomProvider(),
      ),
    );
  }
}
