import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  static Future<bool> isOrganizer(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .collection('members')
        .doc(userId)
        .get();

    return userDoc['role'] == 'organizer';
  }

  static Future<bool> hasSubmittedFeedback(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    QuerySnapshot feedbackQuery = await FirebaseFirestore.instance
        .collection('feedback')
        .where('roomCode', isEqualTo: roomCode)
        .where('userId', isEqualTo: userId)
        .get();

    return feedbackQuery.docs.isNotEmpty;
  }

  static Future<bool> submitFeedback({
    required String roomCode,
    required String feedback,
    required String emoji,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    await FirebaseFirestore.instance.collection('feedback').add({
      'roomCode': roomCode,
      'userId': userId,
      'feedback': feedback,
      'emoji': emoji,
      'timestamp': Timestamp.now(),
    });

    return true;
  }
}
