import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/modules/lobby_room_module/lobby_room_controller.dart';

class LobbyRoomPage extends GetWidget<LobbyRoomController> {
  const LobbyRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your room code:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            Obx(
              () => Text(
                controller.roomCode.value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Copy room code to clipboard or share functionality
              },
              child: const Text('Copy Code'),
            ),
            const SizedBox(height: 16.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Players:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16.0),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.players.length,
                  itemBuilder: (context, index) {
                    return Text(
                      controller.players[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.allReady ? 'All players ready' : 'Waiting for players...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(width: 16.0),
                    if (controller.players.length > 1) // Only show button if multiple players
                      ElevatedButton(
                        onPressed: controller.allReady
                            ? () => controller.startGame()
                            : null, // Disable if not all ready
                        child: const Text('Start Game'),
                      ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
