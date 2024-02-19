import 'package:coup_boardgame/app/data/model/firestore_model/coup_action_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_card_model.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/modules/game_module/widgets/card_widget.dart';
import 'package:coup_boardgame/app/utils/functions/coup_function.dart';
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
        child: Obx(
          () => Column(
            children: [
              // Player information section
              buildPlayerInfo(controller.currentPlayer.value),
              const SizedBox(height: 16.0),
              // Card display section
              buildCardDisplay(controller.currentPlayer.value?.cards ?? []),
              const SizedBox(height: 16.0),
              // Action buttons section
              // buildActionButtons(controller.actions),
              const SizedBox(height: 16.0),
              // Turn indicator and game log
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

  Widget buildPlayerInfo(CoupPlayerModel? player) {
    // Implement UI to display player name, role (if applicable), etc.
    return Column(
      children: [
        Text(
          'Player: ${player?.name}',
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: cards
              .map(
                (card) => SizedBox(
                  width: 150,
                  child: CardWidget(
                    title: card.roleType.name,
                    description: card.roleType.description,
                    icon: card.roleType.icon,
                  ),
                ),
              )
              .toList(),
        ));
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
          'Current Turn: ${controller.currentPlayer.value?.name}',
          style: Get.theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
