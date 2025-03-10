// fetch_details.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> fetchAndSaveUserDetails() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;

  if (user != null) {
    final String? displayName = user.displayName;
    final String? email = user.email;
    final String? phoneNumber = user.phoneNumber;
    final String uid = user.uid;

    // Fetch additional details if required, for now, using what's available in user object.
    Map<String, dynamic> userDetails = {
      'name': displayName ?? '',
      'email': email ?? '',
      'phoneNumber': phoneNumber ?? '',
      'uid': uid,
    };

    // Save to Firestore
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).set(userDetails, SetOptions(merge: true));
  }
}
