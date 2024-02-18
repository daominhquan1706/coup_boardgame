import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:get/get.dart';
import '../../../app/data/provider/lobby_room_provider.dart';

class LobbyRoomController extends GetxController {
  final LobbyRoomProvider? provider;
  LobbyRoomController({this.provider});

  final _text = 'LobbyRoom'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  late final Rx<String> roomCode;


  late final RxList<String> players; // List of player names in the room

  bool get allReady => true; // Flag to indicate if all players are ready

  @override
  void onInit() {
    super.onInit();
    roomCode = generateRoomCode().obs;
    players = <String>[
      'Player 1',
      'Player 2',
      'Player 3',
    ].obs;
  }

  String generateRoomCode() {
    // Implement your logic to generate a unique room code
    // This is a placeholder example
    return 'ABCD-1234';
  }

  //start game
  void startGame() {
    // Implement your logic to start the game
    Get.toNamed(AppRoutes.gameStart);
  }
}
