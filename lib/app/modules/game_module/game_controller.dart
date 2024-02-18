import 'package:coup_boardgame/app/data/model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/coup_player_model.dart';
import 'package:get/get.dart';
import '../../data/provider/game_provider.dart';

class GameStartController extends GetxController {
  final GameProvider? provider;
  GameStartController({this.provider});

  final _text = 'GameStart'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  CoupPlayer currentPlayer = CoupPlayer(
    name: 'Player 1',
    cards: [],
    isAlive: true,
    isHost: true,
  );
}
