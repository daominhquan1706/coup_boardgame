// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoupPlayerModel _$CoupPlayerModelFromJson(Map<String, dynamic> json) =>
    CoupPlayerModel(
      name: json['name'] as String,
      isReady: json['isReady'] as bool,
      cards: (json['cards'] as List<dynamic>)
          .map((e) => CoupCardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAlive: json['isAlive'] as bool,
      coins: json['coins'] as int,
    );

Map<String, dynamic> _$CoupPlayerModelToJson(CoupPlayerModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cards': instance.cards.map((e) => e.toJson()).toList(),
      'isAlive': instance.isAlive,
      'isReady': instance.isReady,
      'coins': instance.coins,
    };
