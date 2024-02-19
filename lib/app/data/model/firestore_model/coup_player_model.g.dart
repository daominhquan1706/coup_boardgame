// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoupPlayer _$CoupPlayerFromJson(Map<String, dynamic> json) => CoupPlayer(
      name: json['name'] as String,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => CoupCardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAlive: json['isAlive'] as bool,
      isHost: json['isHost'] as bool,
    );

Map<String, dynamic> _$CoupPlayerToJson(CoupPlayer instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cards': instance.cards.map((e) => e.toJson()).toList(),
      'isAlive': instance.isAlive,
      'isHost': instance.isHost,
    };
