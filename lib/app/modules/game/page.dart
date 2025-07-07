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
      appBar: AppBar(
        title: Text('GameStart'.tr),
        backgroundColor: Get.theme.primaryColor,
      ),
      body: GetBuilder<GameStartController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (controller.currentRoom == null) {
            return const Center(
              child: Text('Loading game data...'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGameStatus(),
                const SizedBox(height: 16),
                _buildMyPlayerCard(),
                const SizedBox(height: 16),
                _buildOtherPlayersSection(),
                const SizedBox(height: 16),
                _buildGameActions(),
                const SizedBox(height: 16),
                _buildGameControls(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameStatus() {
    return GetBuilder<GameStartController>(
      id: 'gameState',
      builder: (controller) {
        final currentPlayer = controller.currentPlayerTurn;
        final isMyTurn = controller.isMyTurn;
        
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room: ${controller.roomCode}',
                      style: Get.theme.textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMyTurn ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isMyTurn ? 'Your Turn' : 'Waiting',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Turn: ${currentPlayer?.name ?? 'Unknown'}',
                  style: Get.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyPlayerCard() {
    return GetBuilder<GameStartController>(
      id: 'players',
      builder: (controller) {
        final player = controller.mePlayer;
        if (player == null) return const SizedBox();
        
        return Card(
          elevation: 4,
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        player.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You: ${player.name}',
                            style: Get.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Coins: ${player.coins}',
                            style: Get.theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Cards:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCardDisplay(player.cards),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherPlayersSection() {
    return GetBuilder<GameStartController>(
      id: 'players',
      builder: (controller) {
        final otherPlayers = controller.otherPlayers;
        
        if (otherPlayers.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No other players in the game',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other Players:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...otherPlayers.map((player) => _buildPlayerCard(player)),
          ],
        );
      },
    );
  }

  Widget _buildPlayerCard(CoupPlayerModel player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: player.isAlive ? Colors.blue : Colors.grey,
              child: Text(
                player.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: Get.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Coins: ${player.coins} | Cards: ${player.cards.length}',
                    style: Get.theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (!player.isAlive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Eliminated',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameActions() {
    return GetBuilder<GameStartController>(
      id: 'actions',
      builder: (controller) {
        if (!controller.canPerformAction) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Wait for your turn...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Action:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoupFunction.normalAction()
                      .map((action) => _buildActionButton(action))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(CoupActionType action) {
    return GetBuilder<GameStartController>(
      id: 'actions',
      builder: (controller) {
        final player = controller.mePlayer;
        if (player == null) return const SizedBox();
        
        bool enabled = true;
        String? disabledReason;
        
        switch (action) {
          case CoupActionType.assassinate:
            enabled = player.coins >= 3;
            disabledReason = enabled ? null : 'Need 3 coins';
            break;
          case CoupActionType.coup:
            enabled = player.coins >= 7;
            disabledReason = enabled ? null : 'Need 7 coins';
            break;
          default:
            break;
        }
        
        // Force coup if player has more than 10 coins
        if (player.coins > 10 && action != CoupActionType.coup) {
          enabled = false;
          disabledReason = 'Must coup with >10 coins';
        }
        
        return Tooltip(
          message: disabledReason ?? '',
          child: ElevatedButton(
            onPressed: enabled && !controller.isLoading
                ? () => controller.performAction(action)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? Get.theme.primaryColor : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text(
              action.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Game Controls:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GetBuilder<GameStartController>(
              builder: (controller) {
                return ElevatedButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : () => _showEndGameDialog(controller),
                  icon: const Icon(Icons.stop),
                  label: const Text('End Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEndGameDialog(GameStartController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('End Game'),
        content: const Text('Are you sure you want to end the game?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.endGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDisplay(List<CoupCardModel> cards) {
    if (cards.isEmpty) {
      return const Text(
        'No cards',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }
    
    return Row(
      children: cards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < cards.length - 1 ? 8 : 0),
            child: CardWidget(
              title: card.roleType.name,
              description: card.roleType.description,
              icon: card.roleType.icon,
            ),
          ),
        );
      }).toList(),
    );
  }
}
