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
