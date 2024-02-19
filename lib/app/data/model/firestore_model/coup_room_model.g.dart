// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoupRoomModel _$CoupRoomModelFromJson(Map<String, dynamic> json) =>
    CoupRoomModel(
      roomId: json['roomId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => CoupPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      roomState: $enumDecode(_$GameStateEnumMap, json['roomState']),
      deck: (json['deck'] as List<dynamic>)
          .map((e) => CoupCardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastAction:
          $enumDecodeNullable(_$CoupActionTypeEnumMap, json['lastAction']),
    );

Map<String, dynamic> _$CoupRoomModelToJson(CoupRoomModel instance) {
  final val = <String, dynamic>{
    'roomId': instance.roomId,
    'players': instance.players.map((e) => e.toJson()).toList(),
    'roomState': _$GameStateEnumMap[instance.roomState]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('lastAction', _$CoupActionTypeEnumMap[instance.lastAction]);
  val['deck'] = instance.deck.map((e) => e.toJson()).toList();
  return val;
}

const _$GameStateEnumMap = {
  GameState.waiting: 'waiting',
  GameState.playing: 'playing',
  GameState.finished: 'finished',
};

const _$CoupActionTypeEnumMap = {
  CoupActionType.income: 'income',
  CoupActionType.foreignAid: 'foreignAid',
  CoupActionType.coup: 'coup',
  CoupActionType.tax: 'tax',
  CoupActionType.assassinate: 'assassinate',
  CoupActionType.exchange: 'exchange',
  CoupActionType.steal: 'steal',
  CoupActionType.challenge: 'challenge',
  CoupActionType.blockForeignAid: 'blockForeignAid',
  CoupActionType.blockAssassinate: 'blockAssassinate',
  CoupActionType.blockSteal: 'blockSteal',
  CoupActionType.blockExchange: 'blockExchange',
  CoupActionType.blockCoup: 'blockCoup',
  CoupActionType.blockTax: 'blockTax',
  CoupActionType.blockIncome: 'blockIncome',
  CoupActionType.blockChallenge: 'blockChallenge',
  CoupActionType.blockBlockForeignAid: 'blockBlockForeignAid',
  CoupActionType.blockBlockAssassinate: 'blockBlockAssassinate',
  CoupActionType.blockBlockSteal: 'blockBlockSteal',
  CoupActionType.blockBlockExchange: 'blockBlockExchange',
  CoupActionType.blockBlockCoup: 'blockBlockCoup',
  CoupActionType.blockBlockTax: 'blockBlockTax',
  CoupActionType.blockBlockIncome: 'blockBlockIncome',
  CoupActionType.blockBlockChallenge: 'blockBlockChallenge',
};
