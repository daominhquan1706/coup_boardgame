// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coup_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoupCardModel _$CoupCardModelFromJson(Map<String, dynamic> json) =>
    CoupCardModel(
      roleType: $enumDecode(_$CoupRoleTypeEnumMap, json['roleType']),
      isRevealed: json['isRevealed'] as bool,
    );

Map<String, dynamic> _$CoupCardModelToJson(CoupCardModel instance) =>
    <String, dynamic>{
      'roleType': _$CoupRoleTypeEnumMap[instance.roleType]!,
      'isRevealed': instance.isRevealed,
    };

const _$CoupRoleTypeEnumMap = {
  CoupRoleType.duke: 'duke',
  CoupRoleType.assassin: 'assassin',
  CoupRoleType.contessa: 'contessa',
  CoupRoleType.captain: 'captain',
  CoupRoleType.ambassador: 'ambassador',
  CoupRoleType.inquisitor: 'inquisitor',
};
