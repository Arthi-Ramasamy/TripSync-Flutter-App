import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;

  Message({required this.text, required this.senderId, required this.senderName, required this.timestamp});

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      text: doc['text'],
      senderId: doc['senderId'],
      senderName: doc['senderName'],
      timestamp: (doc['timestamp'] as Timestamp).toDate(),
    );
  }
}

class ChatroomBackend {
  static Stream<List<Message>> getMessages(String roomId) {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Message.fromDocument(doc)).toList());
  }

  static Future<void> sendMessage(String roomId, String text, String senderId, String senderName) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
