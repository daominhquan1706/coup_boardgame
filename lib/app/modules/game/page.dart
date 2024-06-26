import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/modules/game/widgets/card_widget.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
import 'package:coup_boardgame/app/utils/widgets/app_divider/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class GamePage extends GetView<GameStartController> {
  const GamePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GameStart'.tr)),
      body: SingleChildScrollView(
        child: Obx(
          () => Column(
            children: [
              buildListPlayers(),
              buildTurnIndicator(),
              ElevatedButton(
                onPressed: () {
                  controller.endGame();
                },
                child: const Text('End Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMePlayerInfo(CoupPlayerModel? player) {
    // Implement UI to display player name, role (if applicable), etc.
    return Column(
      children: [
        Text(
          'Me: ${player?.name}, Coins: ${player?.coins} ',
          style: Get.theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget buildCardDisplay(List<CoupCardModel> cards) {
    // Implement UI to visually represent player's cards and deck.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: cards
          .map(
            (card) => CardWidget(
              title: card.roleType.name,
              description: card.roleType.description,
              icon: card.roleType.icon,
            ),
          )
          .toList(),
    );
  }

  Widget buildActionButtons(CoupActionType action) {
    // Implement UI to display action buttons based on the current player's role.
    bool enabled = true;
    final coin = controller.mePlayer.value?.coins ?? 0;
    switch (action) {
      case CoupActionType.assassin:
        enabled = coin >= 3;
        break;
      case CoupActionType.coup:
        enabled = coin >= 7;
        break;
      default:
        break;
    }

    if (coin > 10 && action != CoupActionType.coup) {
      enabled = false;
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: enabled
              ? () {
                  controller.performAction(action);
                }
              : null,
          child: Text(action.name),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget buildTurnIndicator() {
    // Implement UI to display the current player's turn.
    return Column(
      children: [
        Text(
          'Current Turn: ${controller.currentPlayerTurn?.name}',
          style: Get.theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        Wrap(
          children: [
            ...CoupFunction.normalAction().map((action) => buildActionButtons(action)),
          ],
        )
      ],
    );
  }

  buildListPlayers() {
    return Obx(
      () {
        return Column(
          children: [
            controller.mePlayer.value!,
            ...controller.currentRoom.value!.players
                .where((player) => player != controller.mePlayer.value),
          ].map(
            (player) {
              final isMe = player == controller.mePlayer.value;
              return Card(
                color: isMe ? Colors.green : Colors.red,
                child: Column(
                  children: [
                    Text(
                      'Player: ${player.name}, Coins: ${player.coins}',
                      style: Get.theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16.0),
                    Column(
                      children: [
                        buildCardDisplay(player.cards),
                        const SizedBox(height: 16.0),
                      ],
                    )
                  ],
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }
}
