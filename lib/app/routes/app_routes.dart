part of './app_pages.dart';

class AppRoutes {
  AppRoutes._();
  static const initial = '/';
  static const login = '/login'; // Login page
  static const register = '/register'; // Register page
  static const home = '/home'; // Home page
  static const lobbyRoom = '/coup/:room_code/lobby'; // Lobby Room page
  static const gameStart = '/coup/:room_code/playing'; // Playing page

  static String lobbyRoomPath(String roomCode) => '/coup/$roomCode/lobby';

  static String gameStartPath(String roomCode) => '/coup/$roomCode/playing';
}
