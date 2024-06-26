import 'package:coup_boardgame/app/data/firestore/firestore_service.dart';
import 'package:coup_boardgame/app/data/model/firestore_model/coup_player_model.dart';
import 'package:coup_boardgame/app/utils/widgets/app_divider/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'controller.dart';

class LobbyRoomPage extends GetView<LobbyRoomController> {
  const LobbyRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16.0),
            const SizedBox(height: 16.0),
            Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Show the room code
                  Text(
                    'Your room code: ${controller.roomCode}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // ElevatedButton(
                  //   onPressed: controller.copyCode,
                  //   child: const Text('Copy Code'),
                  // ),

                  const SizedBox(height: 16.0),
                  const AppDivider(), const SizedBox(height: 16.0),
                  Text(
                    'Players:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.room.value?.players.length ?? 0,
                    itemBuilder: (context, index) {
                      return _buildPlayer(controller.room.value!.players[index]);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16.0),
                      if ((controller.room.value?.players.length ?? 0) >=
                          1) // Only show button if multiple players
                        ElevatedButton(
                          onPressed: controller.startGame, // Disable if not all ready
                          child: const Text('Start Game'),
                        ),

                        ElevatedButton(
                        onPressed: controller.addAI, // Disable if not all ready
                        child: const Text('Add AI'),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(CoupPlayerModel player) {
    return ListTile(
      title: Text(player.name),
      trailing: player.isReady ? const Text('Ready') : const Text('Not ready'),
    ).paddingSymmetric(horizontal: 16.0, vertical: 8.0);
  }
}
