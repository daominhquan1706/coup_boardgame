import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:get/get.dart';
import '../../data/provider/game_provider.dart';

class GameStartController extends GetxController {
  final GameProvider? provider;
  GameStartController({this.provider});

  final _text = 'GameStart'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  late Rx<CoupPlayer> currentPlayer;

  List<CoupActionType> actions = [
    CoupActionType.income,
    CoupActionType.foreignAid,
    CoupActionType.tax,
    CoupActionType.steal,
    CoupActionType.exchange,
    CoupActionType.assassinate,
    CoupActionType.coup,
  ];

  @override
  void onInit() {
    super.onInit();

    final userName = Get.parameters['userName'];

    if (userName != null) {
      currentPlayer = CoupPlayer(
        name: userName,
        cards: [
          // CoupCardModel(roleType: RoleType.ambassador),
          // CoupCardModel(roleType: RoleType.assassin),
        ],
        isAlive: true,
        isHost: true,
      ).obs;
    }
  }
}
