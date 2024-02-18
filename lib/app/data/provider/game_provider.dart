import 'package:coup_boardgame/app/data/api/api_connect.dart';
import 'package:coup_boardgame/app/data/model/user.dart';
import 'package:coup_boardgame/app/utils/constants.dart';

class GameProvider {
  GameProvider();

  // Get request
  Future<User> getUser() async {
    return User.fromJson(
      (await ApiConnect.instance.get(EndPoints.user)).getBody(),
    );
  }
}
