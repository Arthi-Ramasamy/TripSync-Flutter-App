// login_page.dart

import 'package:flutter/material.dart';
import 'package:trip_manager1/login_backend.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Import this for storing login state

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    _checkLoginStatus(context);

    return Scaffold(

      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await signInWithGoogle();
            if (user != null) {
              _setLoginStatus(true); // Save login status
              Navigator.pushReplacementNamed(context, '/mytrips');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/google_logo.png', height: 24.0),
              SizedBox(width: 10),
              Text(
                'Sign In with Google',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Check login status
  void _checkLoginStatus(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/mytrips');
    }
  }

  // Set login status
  void _setLoginStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
  }
}
