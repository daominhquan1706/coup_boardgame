import 'package:get/get.dart';

import '../../../app/data/provider/lobby_room_provider.dart';
import '../../../app/modules/lobby_room_module/lobby_room_controller.dart';

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
