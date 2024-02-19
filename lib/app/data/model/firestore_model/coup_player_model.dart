import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coup_player_model.g.dart';

@JsonSerializable()
class CoupPlayer implements BaseModel {
  final String name;
  List<CoupCardModel> cards;
  bool isAlive = true;
  final bool isHost;
  bool isReady = false;

  CoupPlayer({
    required this.name,
    required this.cards,
    required this.isHost,
  });

  factory CoupPlayer.fromJson(Map<String, dynamic> json) => _$CoupPlayerFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupPlayerToJson(this);
}
