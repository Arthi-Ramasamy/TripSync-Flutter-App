import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

const String UPDATE_LOCATION_TASK = "updateLocationTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case UPDATE_LOCATION_TASK:
        await LocationBackend().updateUserLocation();
        break;
    }
    return Future.value(true);
  });
}

class LocationBackend {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _foregroundTimer;

  Future<void> updateUserLocation() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        String username = userDoc['name'];

        // Update the user's location
        await _firestore.collection('users').doc(user.uid).update({
          'location': GeoPoint(position.latitude, position.longitude),
        });
      }
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  void startForegroundUpdates() {
    // Update immediately
    updateUserLocation();

    // Then update every 1 minute when the app is in the foreground
    _foregroundTimer = Timer.periodic(Duration(seconds: 15), (_) {
      updateUserLocation();
    });
  }

  void stopForegroundUpdates() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
  }

  void startBackgroundUpdates() {
    // Register periodic task for background updates
    Workmanager().registerPeriodicTask(
      "1",
      UPDATE_LOCATION_TASK,
      frequency: Duration(seconds: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  void stopBackgroundUpdates() {
    Workmanager().cancelAll();
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}

// Create a global instance of LocationBackend
final locationBackend = LocationBackend();

// Call this function when the app starts
void initializeLocationUpdates() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  bool hasPermission = await locationBackend.requestLocationPermission();
  if (hasPermission) {
    locationBackend.startForegroundUpdates();
    locationBackend.startBackgroundUpdates();
  }
}

// Call this function when the app goes to the background
void onAppBackgrounded() {
  locationBackend.stopForegroundUpdates();
}

// Call this function when the app comes to the foreground
void onAppForegrounded() {
  locationBackend.startForegroundUpdates();
}