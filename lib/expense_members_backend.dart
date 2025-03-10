import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  // Updated factory method with proper type casting
  factory User.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>; // Safely cast the data
    return User(
      id: doc.id,
      name: data['name'] ?? 'Unknown', // Provide a default value if 'name' is null
    );
  }
}

class ExpenseBackend {
  static Future<List<User>> fetchRoomMembers(String roomId) async {
    List<User> members = [];
    var snapshot = await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('members').get();
    for (var doc in snapshot.docs) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(doc.id).get();
      if (userDoc.exists && userDoc.data() != null) {
        members.add(User.fromFirestore(userDoc));
      }
    }
    return members;
  }
}
