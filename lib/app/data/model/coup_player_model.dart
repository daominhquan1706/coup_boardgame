import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/coup_card_model.dart';

class CoupPlayer implements IModel {
  final String name;
  List<CoupCardModel> cards;
  final bool isAlive;
  final bool isHost;

  CoupPlayer({
    required this.name,
    required this.cards,
    required this.isAlive,
    required this.isHost,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cards': cards.map((e) => e.toJson()).toList(),
      'isAlive': isAlive,
      'isHost': isHost,
    };
  }

  factory CoupPlayer.fromJson(Map<String, dynamic> json) {
    return CoupPlayer(
      name: json['name'],
      cards: (json['cards'] as List).map((e) => CoupCardModel.fromJson(e)).toList(),
      isAlive: json['isAlive'],
      isHost: json['isHost'],
    );
  }
}
