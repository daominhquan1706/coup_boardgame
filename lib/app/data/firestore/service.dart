import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRoom(String roomId, List<String> players) async {
    try {
      await _firestore.collection('rooms').doc(roomId).set({
        'players': players,
      });
      print('Room created successfully');
    } catch (e) {
      print('Failed to create room: $e');
    }
  }
}
