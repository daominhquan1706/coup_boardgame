// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_action_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoupActionModel _$CoupActionModelFromJson(Map<String, dynamic> json) =>
    CoupActionModel(
      source: CoupPlayerModel.fromJson(json['source'] as Map<String, dynamic>),
      actionType: $enumDecode(_$CoupActionTypeEnumMap, json['actionType']),
      target: json['target'] == null
          ? null
          : CoupPlayerModel.fromJson(json['target'] as Map<String, dynamic>),
    )
      ..listNeedVote = (json['listNeedVote'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..listVoted =
          (json['listVoted'] as List<dynamic>).map((e) => e as String).toList()
      ..preventedBy = json['preventedBy'] as String?;

Map<String, dynamic> _$CoupActionModelToJson(CoupActionModel instance) {
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
  val['listNeedVote'] = instance.listNeedVote;
  val['listVoted'] = instance.listVoted;
  writeNotNull('preventedBy', instance.preventedBy);
  return val;
}

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
