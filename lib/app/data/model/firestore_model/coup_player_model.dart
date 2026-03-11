import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coup_player_model.g.dart';

@JsonSerializable()
class CoupPlayerModel implements BaseModel {
  String name;
  String? displayName;
  List<CoupCardModel> cards;
  bool isAlive;
  bool isReady;
  int coins;
  bool isBot;

  String get shownName => (displayName?.trim().isNotEmpty ?? false) ? displayName!.trim() : name;

  CoupPlayerModel({
    required this.name,
    this.displayName,
    required this.isReady,
    required this.cards,
    required this.isAlive,
    required this.coins,
    this.isBot = false,
  });

  factory CoupPlayerModel.fromJson(Map<String, dynamic> json) => _$CoupPlayerModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupPlayerModelToJson(this);
}
