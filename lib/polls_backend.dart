import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollsBackend {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPollsInRoom(String roomCode) {
    return _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('polls')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> voteOnPoll({
    required String roomCode,
    required String pollId,
    required String selectedOption,
  }) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch the username from the "users" collection
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String username = userDoc.get('name');

      DocumentReference pollRef = _firestore
          .collection('rooms')
          .doc(roomCode)
          .collection('polls')
          .doc(pollId);

      // Fetch the poll document
      DocumentSnapshot pollDoc = await pollRef.get();
      Map<String, dynamic> votes = pollDoc.get('votes') as Map<String, dynamic>? ?? {};
      Map<String, dynamic> voteCounts = pollDoc.get('voteCounts') as Map<String, dynamic>? ?? {};

      // Check if the user has already voted
      if (votes.containsKey(username)) {
        // User has already voted
        throw Exception('User has already voted.');
      }

      // Update the votes
      votes[username] = selectedOption;

      // Increment the vote count for the selected option
      voteCounts[selectedOption] = (voteCounts[selectedOption] ?? 0) + 1;

      // Save the updates
      await pollRef.update({
        'votes': votes,
        'voteCounts': voteCounts,
      });
    }
  }

  Future<bool> hasUserVoted({
    required String roomCode,
    required String pollId,
  }) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch the username from the "users" collection
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String username = userDoc.get('name');

      DocumentSnapshot pollDoc = await _firestore
          .collection('rooms')
          .doc(roomCode)
          .collection('polls')
          .doc(pollId)
          .get();

      Map<String, dynamic>? votes = pollDoc.get('votes') as Map<String, dynamic>?;

      return votes != null && votes.containsKey(username);
    }

    return false;
  }
}
