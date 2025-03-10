import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Announcement {
  final String id; // Added this to track the document ID for deletion
  final String text;
  final DateTime timestamp;

  Announcement({
    required this.id, // Track document ID for deletion
    required this.text,
    required this.timestamp,
  });

  // Factory method to create an Announcement object from Firestore document
  factory Announcement.fromDocument(DocumentSnapshot doc) {
    return Announcement(
      id: doc.id, // Get the document ID for deletion purposes
      text: doc['text'],
      timestamp: (doc['timestamp'] as Timestamp).toDate(),
    );
  }
}

class AnnouncementsBackend {
  // Post a new announcement to the Firestore database
  static Future<void> postAnnouncement(String roomId, String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('announcements')
          .add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(), // Record server timestamp
      });
    }
  }

  // Retrieve all announcements for a specific room in descending order by timestamp
  static Stream<List<Announcement>> getAnnouncements(String roomId) {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Announcement.fromDocument(doc)).toList());
  }

  // Check if the current user is an organiser
  static Future<bool> isUserOrganiser(String roomId, String userId) async {
    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(userId)
        .get();
    return roomDoc.exists && roomDoc.data()?['role'] == 'organiser';
  }

  // Delete a specific announcement from Firestore
  static Future<void> deleteAnnouncement(String roomId, String announcementId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }
}
