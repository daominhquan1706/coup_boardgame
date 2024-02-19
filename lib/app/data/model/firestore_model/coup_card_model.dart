import 'package:coup_boardgame/app/data/model/abstract_model.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
part 'coup_card_model.g.dart';
enum CoupRoleType {
  duke,
  assassin,
  contessa,
  captain,
  ambassador,
  inquisitor,
}

extension CoupCardTypeExtension on CoupRoleType {
  String get name {
    switch (this) {
      case CoupRoleType.duke:
        return 'Duke';
      case CoupRoleType.assassin:
        return 'Assassin';
      case CoupRoleType.contessa:
        return 'Contessa';
      case CoupRoleType.captain:
        return 'Captain';
      case CoupRoleType.ambassador:
        return 'Ambassador';
      case CoupRoleType.inquisitor:
        return 'Inquisitor';
    }
  }

  String get description {
    switch (this) {
      case CoupRoleType.duke:
        return 'Tax: Take three coins from the treasury.';
      case CoupRoleType.assassin:
        return 'Assassinate: Pay three coins and try to assassinate another player.';
      case CoupRoleType.contessa:
        return 'Block: Block an assassination attempt against yourself.';
      case CoupRoleType.captain:
        return 'Steal: Take two coins from another player.';
      case CoupRoleType.ambassador:
        return 'Exchange: Draw two cards from the Court (the deck), choose which (if any) to exchange with your cards, and return two.';
      case CoupRoleType.inquisitor:
        return 'Exchange: Draw one card from the Court (the deck), choose which (if any) to exchange with your cards, and return one.';
    }
  }

  IconData get icon {
    switch (this) {
      case CoupRoleType.duke:
        return Icons.account_balance;
      case CoupRoleType.assassin:
        return Icons.emoji_people;
      case CoupRoleType.contessa:
        return Icons.security;
      case CoupRoleType.captain:
        return Icons.account_balance_wallet;
      case CoupRoleType.ambassador:
        return Icons.account_balance_sharp;
      case CoupRoleType.inquisitor:
        // not the same as the ambassador icon, but it's close enough
        return Icons.account_balance_outlined;
    }
  }
}


@JsonSerializable()
class CoupCardModel implements BaseModel {
  final CoupRoleType roleType;
  final bool isRevealed;

  CoupCardModel({
    required this.roleType,
    required this.isRevealed,
  });

  factory CoupCardModel.fromJson(Map<String, dynamic> json) => _$CoupCardModelFromJson(json);

  Map<String, dynamic> toJson() => _$CoupCardModelToJson(this);
}
