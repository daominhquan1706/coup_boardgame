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
    )
      ..currentTurn = json['currentTurn'] as String?
      ..currentAction = json['currentAction'] == null
          ? null
          : CoupActionModel.fromJson(
              json['currentAction'] as Map<String, dynamic>);

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
  writeNotNull('currentTurn', instance.currentTurn);
  writeNotNull('currentAction', instance.currentAction?.toJson());
  return val;
}

const _$GameStateEnumMap = {
  GameState.waiting: 'waiting',
  GameState.playing: 'playing',
};

const _$CoupActionTypeEnumMap = {
  CoupActionType.income: 'income',
  CoupActionType.foreignAid: 'foreignAid',
  CoupActionType.coup: 'coup',
  CoupActionType.taxByDuke: 'taxByDuke',
  CoupActionType.assassinate: 'assassinate',
  CoupActionType.exchangeByAmbassador: 'exchangeByAmbassador',
  CoupActionType.exchangeDeskCardByInquisitor: 'exchangeDeskCardByInquisitor',
  CoupActionType.exchangeUserCardInquisitor: 'exchangeUserCardInquisitor',
  CoupActionType.stealByCaptain: 'stealByCaptain',
  CoupActionType.challengeAssassinate: 'challengeAssassinate',
  CoupActionType.challengeSteal: 'challengeSteal',
  CoupActionType.challengeExchangeByAmbassador: 'challengeExchangeByAmbassador',
  CoupActionType.challengeExchangeByInquisitor: 'challengeExchangeByInquisitor',
  CoupActionType.challengeTax: 'challengeTax',
  CoupActionType.blockForeignAidByDuke: 'blockForeignAidByDuke',
  CoupActionType.blockAssassinateByContessa: 'blockAssassinateByContessa',
  CoupActionType.blockStealByAmbassador: 'blockStealByAmbassador',
  CoupActionType.blockStealByCaptain: 'blockStealByCaptain',
  CoupActionType.blockStealByInquisitor: 'blockStealByInquisitor',
};
