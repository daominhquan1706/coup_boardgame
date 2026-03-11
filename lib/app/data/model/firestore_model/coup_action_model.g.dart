// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_action_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoupActionModel _$CoupActionModelFromJson(Map<String, dynamic> json) =>
    CoupActionModel(
      actionId: json['actionId'] as String?,
      source: CoupPlayerModel.fromJson(json['source'] as Map<String, dynamic>),
      actionType: $enumDecode(_$CoupActionTypeEnumMap, json['actionType']),
      target: json['target'] == null
          ? null
          : CoupPlayerModel.fromJson(json['target'] as Map<String, dynamic>),
      status: json['status'] as String?,
      claimedCard: json['claimedCard'] as String?,
      challengerId: json['challengerId'] as String?,
      blockerId: json['blockerId'] as String?,
      blockClaimedCard: json['blockClaimedCard'] as String?,
    )
      ..listNeedVote = (json['listNeedVote'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..listVoted =
          (json['listVoted'] as List<dynamic>).map((e) => e as String).toList()
      ..preventedBy = json['preventedBy'] as String?
      ..isFakeAction = json['isFakeAction'] as bool?;

Map<String, dynamic> _$CoupActionModelToJson(CoupActionModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('actionId', instance.actionId);
  val['source'] = instance.source.toJson();
  val['actionType'] = _$CoupActionTypeEnumMap[instance.actionType]!;
  writeNotNull('target', instance.target?.toJson());
  writeNotNull('status', instance.status);
  writeNotNull('claimedCard', instance.claimedCard);
  writeNotNull('challengerId', instance.challengerId);
  writeNotNull('blockerId', instance.blockerId);
  writeNotNull('blockClaimedCard', instance.blockClaimedCard);
  val['listNeedVote'] = instance.listNeedVote;
  val['listVoted'] = instance.listVoted;
  writeNotNull('preventedBy', instance.preventedBy);
  writeNotNull('isFakeAction', instance.isFakeAction);
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
