import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<String> createRoom(String roomName, String organiserId) async {
  String roomCode = _generateRoomCode();
  DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomCode);

  // Set the initial room data with the organizer ID in the member_ids array
  await roomRef.set({
    'room_name': roomName,
    'organiser_id': organiserId,
    'created_at': FieldValue.serverTimestamp(),
    'room_code': roomCode,
    'member_ids': [organiserId],  // Initialize with organizer's ID
  });

  // Also add organizer to the members subcollection with role
  await roomRef.collection('members').doc(organiserId).set({
    'role': 'organiser',
  });

  return roomCode;
}

String _generateRoomCode() {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();
  return String.fromCharCodes(Iterable.generate(
    6,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
  ));
}
