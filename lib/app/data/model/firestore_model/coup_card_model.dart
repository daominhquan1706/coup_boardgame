import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
part 'coup_card_model.g.dart';

@JsonSerializable()
class CoupCardModel implements BaseModel {
  final CoupRoleType roleType;
  final bool isRevealed;

  CoupCardModel({
    required this.roleType,
    required this.isRevealed,
  });

  factory CoupCardModel.fromJson(Map<String, dynamic> json) => _$CoupCardModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CoupCardModelToJson(this);
}
