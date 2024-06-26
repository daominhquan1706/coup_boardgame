import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:flutter/material.dart';

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
      CoupActionType.taxByDuke,
      CoupActionType.stealByCaptain,
      CoupActionType.assassinate,
      CoupActionType.exchangeByAmbassador,
      CoupActionType.income,
      CoupActionType.foreignAid,
      CoupActionType.coup,
    ];
  }

  static bool isNeedPlayerTarget(CoupActionType action) {
    switch (action) {
      case CoupActionType.assassinate:
      case CoupActionType.stealByCaptain:
      case CoupActionType.exchangeUserCardInquisitor:
      case CoupActionType.coup:
        return true;
      default:
        return false;
    }
  }

  static List<CoupActionType> nextActions(CoupActionType action) {
    switch (action) {
      case CoupActionType.foreignAid:
        return [
          CoupActionType.blockForeignAidByDuke,
        ];

      case CoupActionType.assassinate:
        return [
          CoupActionType.challengeAssassinate,
          CoupActionType.blockAssassinateByContessa,
        ];
      case CoupActionType.stealByCaptain:
        return [
          CoupActionType.challengeSteal,
          CoupActionType.blockStealByAmbassador,
          CoupActionType.blockStealByCaptain,
          CoupActionType.blockStealByInquisitor,
        ];
      case CoupActionType.exchangeUserCardInquisitor:
        return [
          CoupActionType.challengeExchangeByInquisitor,
        ];
      case CoupActionType.exchangeByAmbassador:
        return [
          CoupActionType.challengeExchangeByAmbassador,
        ];
      case CoupActionType.taxByDuke:
        return [
          CoupActionType.challengeTax,
        ];
      default:
        return [];
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
