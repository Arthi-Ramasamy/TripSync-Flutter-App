import 'package:flutter/material.dart';
import 'package:trip_manager1/login_page.dart';
import 'package:trip_manager1/mytrips_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trip_manager1/location_backend.dart'; // Import the LocationBackend
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      onAppForegrounded();
    }
  }

  void _initializeLocationUpdates() async {
    // We need to delay this call slightly to ensure we have a valid BuildContext
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeLocationUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Manager App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/mytrips': (context) => MyTripsPage(),
      },
    );
  }
}
