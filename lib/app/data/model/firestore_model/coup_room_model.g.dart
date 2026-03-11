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
      roomState: _gameStateFromJson(json['status'] as String?),
      phase: json['phase'] == null
          ? GamePhase.waiting
          : _gamePhaseFromJson(json['phase'] as String?),
      deck: (json['deck'] as List<dynamic>)
          .map((e) => CoupCardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hostId: json['hostId'] as String?,
      lastAction:
          $enumDecodeNullable(_$CoupActionTypeEnumMap, json['lastAction']),
      currentTurn: json['currentTurnPlayerId'] as String?,
      winnerId: json['winnerId'] as String?,
      playerOrder: (json['playerOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      currentAction: json['currentAction'] == null
          ? null
          : CoupActionModel.fromJson(
              json['currentAction'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CoupRoomModelToJson(CoupRoomModel instance) {
  final val = <String, dynamic>{
    'roomId': instance.roomId,
    'players': instance.players.map((e) => e.toJson()).toList(),
    'status': _gameStateToJson(instance.roomState),
    'phase': _gamePhaseToJson(instance.phase),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('hostId', instance.hostId);
  writeNotNull('lastAction', _$CoupActionTypeEnumMap[instance.lastAction]);
  val['deck'] = instance.deck.map((e) => e.toJson()).toList();
  writeNotNull('currentTurnPlayerId', instance.currentTurn);
  writeNotNull('winnerId', instance.winnerId);
  val['playerOrder'] = instance.playerOrder;
  writeNotNull('currentAction', instance.currentAction?.toJson());
  return val;
}

const _$CoupActionTypeEnumMap = {
  CoupActionType.income: 'income',
  CoupActionType.foreignAid: 'foreignAid',
  CoupActionType.coup: 'coup',
  CoupActionType.duke: 'duke',
  CoupActionType.captain: 'captain',
  CoupActionType.ambassador: 'ambassador',
  CoupActionType.assassin: 'assassin',
  CoupActionType.contessa: 'contessa',
  CoupActionType.inquisitor: 'inquisitor',
};
