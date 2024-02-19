// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_action_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionModel _$ActionModelFromJson(Map<String, dynamic> json) => ActionModel(
      source: CoupPlayer.fromJson(json['source'] as Map<String, dynamic>),
      actionType: $enumDecode(_$CoupActionTypeEnumMap, json['actionType']),
      target: json['target'] == null
          ? null
          : CoupPlayer.fromJson(json['target'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ActionModelToJson(ActionModel instance) {
  final val = <String, dynamic>{
    'source': instance.source.toJson(),
    'actionType': _$CoupActionTypeEnumMap[instance.actionType]!,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('target', instance.target?.toJson());
  return val;
}

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
