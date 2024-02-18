import 'package:coup_boardgame/app/data/model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/coup_player_model.dart';
import 'package:coup_boardgame/app/modules/game_module/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'game_controller.dart';

class GamePage extends GetWidget<GameStartController> {
  const GamePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GameStart'.tr)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Player information section
            buildPlayerInfo(controller.currentPlayer),
            const SizedBox(height: 16.0),
            // Card display section
            buildCardDisplay(controller.currentPlayer.cards),
            const SizedBox(height: 16.0),
            // Action buttons section
            // buildActionButtons(controller.actions),
            const SizedBox(height: 16.0),
            // Turn indicator and game log
            buildTurnIndicator(),
            buildGameLog(),
          ],
        ),
      ),
    );
  }

  Widget buildPlayerInfo(CoupPlayer player) {
    // Implement UI to display player name, role (if applicable), etc.
    return Column(
      children: [
        Text(
          'Player: ${player.name}',
          style: Get.theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget buildCardDisplay(List<CoupCardModel> cards) {
    // Implement UI to visually represent player's cards and deck.
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 150,
            child: CardWidget(
              title: cards[index].roleType.name,
              description: cards[index].roleType.description,
              icon: cards[index].roleType.icon,
            ),
          );
        },
      ),
    );
  }

  Widget buildActionButtons(CoupActionType action) {
    // Implement UI to display action buttons based on the current player's role.
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Handle "Income" button press
          },
          child: const Text('Income'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            // Handle "Foreign Aid" button press
          },
          child: const Text('Foreign Aid'),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            // Handle "Coup" button press
          },
          child: const Text('Coup'),
        ),
      ],
    );
  }

  Widget buildTurnIndicator() {
    // Implement UI to display the current player's turn.
    return Column(
      children: [
        Text(
          'Current Turn: ${controller.currentPlayer.name}',
          style: Get.theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget buildGameLog() {
    // Implement UI to display a history of recent actions.
    return Column(
      children: [
        Text(
          'Game Log',
          style: Get.theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        // ListView.builder(
        //   shrinkWrap: true,
        //   itemCount: controller.gameLog.length,
        //   itemBuilder: (context, index) {
        //     return Text(
        //       controller.gameLog[index],
        //       style: Get.theme.textTheme.bodyLarge,
        //     );
        //   },
        // ),
      ],
    );
  }
}
