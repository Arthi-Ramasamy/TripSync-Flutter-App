// user_settings.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mytrips_backend.dart'; // For sign-out functionality

class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  void _loadUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'];
          _emailController.text = userDoc['email'];
          _phoneController.text = userDoc['phone'];
        });
      }
    }
  }

  void _updateUserData() async {
    if (_user != null) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              readOnly: true,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUserData,
              child: Text('Update'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => MyTripsBackend().signOut(context),
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
