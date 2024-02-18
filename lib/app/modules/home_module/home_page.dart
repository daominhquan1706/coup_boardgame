import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/modules/home_module/home_controller.dart';

class HomePage extends GetWidget<HomeController> {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home'.tr)),
      body: Obx(() => Text(controller.text)),
    );
  }
}
