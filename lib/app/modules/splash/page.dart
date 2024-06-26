import 'package:coup_boardgame/app/modules/splash/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:coup_boardgame/app/routes/app_pages.dart';
import 'package:coup_boardgame/app/utils/widgets/app_bar/custom_app_bar.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    ///Your widget
    return Scaffold(
      appBar: CustomAppBar(),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlutterLogo(
                  size: Get.size.width * 0.4,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Loading...',
                  style: Get.theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
