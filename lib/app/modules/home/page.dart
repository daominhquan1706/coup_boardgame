import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/widgets/app_divider/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coup Board Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: controller.name.call,
                decoration: const InputDecoration(
                  labelText: 'User name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.name.isNotEmpty == true
                    ? () {
                        // route to the lobby room page
                        controller.onTapCreateRoom();
                      }
                    : null,
                child: const Text('Create Room'),
              ),
            ),
            const SizedBox(height: 16.0),
            const AppDivider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: controller.roomCode.call,
                decoration: const InputDecoration(
                  labelText: 'Room code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.roomCode.isNotEmpty == true
                    ? () {
                        controller.onTapJoinRoom();
                      }
                    : null,
                child: const Text('Join Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
