import 'package:coup_boardgame/app/utils/functions/coup_function.dart';

class EndPoints {
  const EndPoints._();

  static const String baseUrl = 'https://yourapi/';
  static const String login = "auth/login";
  static const String user = "userdata";

  static const Duration timeout = Duration(seconds: 30);

  static const String token = 'authToken';

  // maximum players in a room
}

enum LoadDataState { initialize, loading, loaded, error, timeout, unknownerror }

class Constant {
  const Constant._();

  // maximum players in a room
  static const int maxPlayersPerRoom = 6;
}

class AssetPaths {
  const AssetPaths._();

  static const String roleCardsRoot = 'assets/images/roles';
  static const String roleCardFrontFileName = 'card_front.png';

  static String roleDirectory(CoupRoleType role) => '$roleCardsRoot/${role.firestoreValue}';

  static String roleCardFront(CoupRoleType role) => '${roleDirectory(role)}/$roleCardFrontFileName';

  static String roleReserveSlot(CoupRoleType role, int slot) {
    if (slot < 1 || slot > 8) {
      throw RangeError.range(slot, 1, 8, 'slot');
    }
    return '${roleDirectory(role)}/reserve_${slot.toString().padLeft(2, '0')}.png';
  }

  static List<String> roleReserveSlots(CoupRoleType role) {
    return List<String>.generate(
      8,
      (index) => roleReserveSlot(role, index + 1),
      growable: false,
    );
  }
}
