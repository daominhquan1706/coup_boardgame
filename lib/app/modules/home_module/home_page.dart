import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/modules/home_module/home_controller.dart';

class HomePage extends GetWidget<HomeController> {
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
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // route to the lobby room page
                    Get.toNamed(AppRoutes.lobbyRoom);
                  },
                  child: const Text('Create Room'),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Handle "Join room" button press
                    // Navigate to room joining page or logic
                  },
                  child: const Text('Join Room'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
