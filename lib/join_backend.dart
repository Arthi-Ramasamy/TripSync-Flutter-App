import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> joinRoom(String roomCode, String userId) async {
  DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomCode);
  DocumentSnapshot roomDoc = await roomRef.get();

  if (!roomDoc.exists) {
    return false;
  }

  // Update room document to include the new member ID in the member_ids array
  await roomRef.update({
    'member_ids': FieldValue.arrayUnion([userId]),
  });

  // Add new member as participant in the members subcollection
  await roomRef.collection('members').doc(userId).set({
    'role': 'participant',
  });

  return true;
}
