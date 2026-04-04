import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum CoupActionType {
  income,
  foreignAid,
  coup,
  duke,
  captain,
  ambassador,
  assassin,
  contessa,
  inquisitor,
}

extension CoupActionTypeX on CoupActionType {
  String get firestoreType {
    switch (this) {
      case CoupActionType.income:
        return 'income';
      case CoupActionType.foreignAid:
        return 'foreign_aid';
      case CoupActionType.coup:
        return 'coup';
      case CoupActionType.duke:
        return 'tax';
      case CoupActionType.captain:
        return 'steal';
      case CoupActionType.ambassador:
        return 'exchange';
      case CoupActionType.assassin:
        return 'assassinate';
      case CoupActionType.contessa:
        return 'block_contessa';
      case CoupActionType.inquisitor:
        return 'inquisitor';
    }
  }

  bool get isChallengeable {
    switch (this) {
      case CoupActionType.duke:
      case CoupActionType.captain:
      case CoupActionType.ambassador:
      case CoupActionType.assassin:
      case CoupActionType.inquisitor:
        return true;
      default:
        return false;
    }
  }

  bool get isBlockable {
    switch (this) {
      case CoupActionType.foreignAid:
      case CoupActionType.captain:
      case CoupActionType.assassin:
        return true;
      default:
        return false;
    }
  }

  CoupRoleType? get claimedRole {
    switch (this) {
      case CoupActionType.duke:
        return CoupRoleType.duke;
      case CoupActionType.captain:
        return CoupRoleType.captain;
      case CoupActionType.ambassador:
        return CoupRoleType.ambassador;
      case CoupActionType.assassin:
        return CoupRoleType.assassin;
      case CoupActionType.contessa:
        return CoupRoleType.contessa;
      case CoupActionType.inquisitor:
        return CoupRoleType.inquisitor;
      default:
        return null;
    }
  }

  static CoupActionType fromFirestoreType(String value) {
    switch (value) {
      case 'income':
        return CoupActionType.income;
      case 'foreign_aid':
        return CoupActionType.foreignAid;
      case 'coup':
        return CoupActionType.coup;
      case 'tax':
        return CoupActionType.duke;
      case 'steal':
        return CoupActionType.captain;
      case 'exchange':
        return CoupActionType.ambassador;
      case 'assassinate':
        return CoupActionType.assassin;
      case 'inquisitor':
        return CoupActionType.inquisitor;
      default:
        return CoupActionType.income;
    }
  }
}

enum CoupRoleType {
  duke,
  assassin,
  contessa,
  captain,
  ambassador,
  inquisitor,
}

extension CoupRoleTypeX on CoupRoleType {
  String get firestoreValue {
    switch (this) {
      case CoupRoleType.duke:
        return 'duke';
      case CoupRoleType.assassin:
        return 'assassin';
      case CoupRoleType.contessa:
        return 'contessa';
      case CoupRoleType.captain:
        return 'captain';
      case CoupRoleType.ambassador:
        return 'ambassador';
      case CoupRoleType.inquisitor:
        return 'inquisitor';
    }
  }

  static CoupRoleType fromFirestoreValue(String value) {
    switch (value) {
      case 'duke':
        return CoupRoleType.duke;
      case 'assassin':
        return CoupRoleType.assassin;
      case 'contessa':
        return CoupRoleType.contessa;
      case 'captain':
        return CoupRoleType.captain;
      case 'ambassador':
        return CoupRoleType.ambassador;
      case 'inquisitor':
        return CoupRoleType.inquisitor;
      default:
        return CoupRoleType.duke;
    }
  }

  static CoupRoleType? tryFromFirestoreValue(String? value) {
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'duke':
        return CoupRoleType.duke;
      case 'assassin':
        return CoupRoleType.assassin;
      case 'contessa':
        return CoupRoleType.contessa;
      case 'captain':
        return CoupRoleType.captain;
      case 'ambassador':
        return CoupRoleType.ambassador;
      case 'inquisitor':
        return CoupRoleType.inquisitor;
      default:
        return null;
    }
  }
}

extension CoupCardTypeExtension on CoupRoleType {
  String get titleKey {
    switch (this) {
      case CoupRoleType.duke:
        return 'roleNameDuke';
      case CoupRoleType.assassin:
        return 'roleNameAssassin';
      case CoupRoleType.contessa:
        return 'roleNameContessa';
      case CoupRoleType.captain:
        return 'roleNameCaptain';
      case CoupRoleType.ambassador:
        return 'roleNameAmbassador';
      case CoupRoleType.inquisitor:
        return 'roleNameInquisitor';
    }
  }

  String get shortGuideKey {
    switch (this) {
      case CoupRoleType.duke:
        return 'roleGuideDuke';
      case CoupRoleType.assassin:
        return 'roleGuideAssassin';
      case CoupRoleType.contessa:
        return 'roleGuideContessa';
      case CoupRoleType.captain:
        return 'roleGuideCaptain';
      case CoupRoleType.ambassador:
        return 'roleGuideAmbassador';
      case CoupRoleType.inquisitor:
        return 'roleGuideInquisitor';
    }
  }

  String get localizedName => titleKey.tr;

  String get localizedInitial {
    final value = localizedName.trim();
    if (value.isEmpty) return '?';
    return value[0].toUpperCase();
  }

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

class CoupFunction {
  static int numCardsPerRole(int numPlayers) {
    switch (numPlayers) {
      case 3:
        return 3;
      case 4:
        return 3;
      case 5:
        return 3;
      case 6:
        return 4;
      case 7:
        return 4;
      case 8:
        return 5;
      case 9:
        return 5;
      case 10:
        return 6;
      default:
        return 3;
    }
  }

  static List<CoupCardModel> generateDeck(int numPlayers) {
    final deck = <CoupCardModel>[];
    final numRoles = numCardsPerRole(numPlayers);
    for (var i = 0; i < numRoles; i++) {
      deck.add(createCard(CoupRoleType.ambassador));
      deck.add(createCard(CoupRoleType.assassin));
      deck.add(createCard(CoupRoleType.captain));
      deck.add(createCard(CoupRoleType.contessa));
      deck.add(createCard(CoupRoleType.duke));
    }
    return deck..shuffle();
  }

  static CoupCardModel createCard(CoupRoleType role) {
    return CoupCardModel(
      roleType: role,
      isRevealed: false,
    );
  }

  static CoupPlayerModel nextPlayer(List<CoupPlayerModel> players, CoupPlayerModel currentPlayer) {
    final index = players.indexOf(currentPlayer);
    if (index == players.length - 1) {
      return players.first;
    } else {
      return players[index + 1];
    }
  }

  static List<CoupActionType> firstActions(CoupPlayerModel player) {
    final actions = <CoupActionType>[];
    if (player.coins < 10) {
      return [CoupActionType.income, CoupActionType.foreignAid, CoupActionType.coup];
    }
    return actions;
  }

  static List<CoupActionType> normalAction() {
    return [
      CoupActionType.income,
      CoupActionType.foreignAid,
      CoupActionType.coup,
      CoupActionType.duke,
      CoupActionType.assassin,
      CoupActionType.captain,
      CoupActionType.ambassador,
    ];
  }

  static bool isNeedPlayerTarget(CoupActionType action) {
    switch (action) {
      case CoupActionType.coup:
      case CoupActionType.assassin:
      case CoupActionType.captain:
        return true;
      default:
        return false;
    }
  }

  static List<CoupCardModel> exchangeCards(List<CoupCardModel> cards, List<CoupCardModel> deck) {
    final newCards = <CoupCardModel>[];
    final newDeck = List<CoupCardModel>.from(deck);
    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      if (card.isRevealed) {
        newCards.add(newDeck.removeLast());
      } else {
        newCards.add(card);
      }
    }
    return newCards;
  }

  static List<CoupCardModel> drawCards(List<CoupCardModel> newDeck, int i) {
    return newDeck.sublist(0, i);
  }

  static bool hasRole(CoupPlayerModel coupPlayerModel, CoupRoleType role) {
    return coupPlayerModel.cards.any((element) => element.roleType == role);
  }
}
