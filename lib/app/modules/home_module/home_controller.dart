import 'package:coup_boardgame/app/data/model/coup_action_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../app/data/provider/home_provider.dart';

class HomeController extends GetxController {
  final HomeProvider? provider;
  HomeController({this.provider});

  final _text = 'Home'.obs;
  set text(text) => _text.value = text;
  get text => _text.value;

  // text field controller for name input
  final nameController = TextEditingController();

  List<CoupActionType> actions = [
    CoupActionType.income,
    CoupActionType.foreignAid,
    CoupActionType.tax,
    CoupActionType.steal,
    CoupActionType.exchange,
    CoupActionType.assassinate,
    CoupActionType.coup,
  ];

  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.signInAnonymously().then((value) {
      print('User ID: ${value.user!.uid}');
    });
  }
}
