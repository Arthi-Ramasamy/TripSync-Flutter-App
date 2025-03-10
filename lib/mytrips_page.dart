import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:trip_manager1/create_backend.dart';
import 'package:trip_manager1/join_backend.dart';
import 'dashboard_page.dart';
import 'user_settings.dart';

class MyTripsPage extends StatefulWidget {
  @override
  _MyTripsPageState createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _requestLocationPermission();
  }

  void _requestLocationPermission() async {
    await Geolocator.requestPermission();
  }

  void _showCreateRoomDialog() {
    TextEditingController roomNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create Room"),
          content: TextField(
            controller: roomNameController,
            decoration: InputDecoration(hintText: "Enter Room Name"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String roomCode = await createRoom(roomNameController.text, _user!.uid);
                Navigator.of(context).pop();
                _showRoomCodeDialog(roomCode);
                setState(() {});
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }
  void _showRoomCodeDialog(String roomCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Room Created"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Room Code: $roomCode"),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _joinRoom(String roomCode) async {
    bool success = await joinRoom(roomCode, _user!.uid);
    if (success) {
      Navigator.of(context).pop();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to join the room")));
    }
  }

  void _showJoinRoomDialog() {
    TextEditingController roomCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Join Room"),
          content: TextField(
            controller: roomCodeController,
            decoration: InputDecoration(hintText: "Enter Room Code"),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _joinRoom(roomCodeController.text),
              child: Text("Join"),
            ),
          ],
        );
      },
    );
  }
  Future<String> _getOrganizerName(String organiserId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(organiserId).get();
    if (userDoc.exists && userDoc.data() != null) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['name'] ?? 'No name provided';
    }
    return "Unknown Organizer";  // Fallback to ID if no name is found
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('MY TRIPS'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserSettingsPage()),
                );
              },
            ),
          ],
        ),
        body: // Existing UI elements...
        Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .where('member_ids', arrayContains: _user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Center(child: Text("No trips found."));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((DocumentSnapshot doc) {
                      // Ensure data is a Map and not null before casting
                      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
                      if (data == null) {
                        // Handle the case where there is no data
                        return ListTile(title: Text("No Data"));
                      }

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('rooms').doc(doc.id).collection('members').get(),
                        builder: (context, memberSnapshot) {
                          if (!memberSnapshot.hasData) {
                            return ListTile(
                              title: Text(data['room_name'] ?? "Unknown Room"),
                              subtitle: Text("Loading members..."),
                            );
                          }

                          var members = memberSnapshot.data!.docs;
                          var isOrganiser = members.any((DocumentSnapshot m) =>
                          m.id == _user!.uid && (m.data() as Map<String, dynamic>?)?['role'] == 'organiser');
                          int memberCount = members.length;

                          return ListTile(
                            title: Text(data['room_name'] ?? "Unnamed Room"),
                            subtitle: FutureBuilder<String>(
                              future: _getOrganizerName(data['organiser_id'] as String? ?? "Unknown"),
                              builder: (context, organiserSnapshot) {
                                return Text("Creator: ${organiserSnapshot.data ?? "Loading..."}");
                              },
                            ),
                            trailing: Text("Members: $memberCount"),
                            tileColor: isOrganiser ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashboardPage(
                                    roomName: data['room_name'] ?? "Unnamed Room",
                                    roomCode: doc.id,
                                    organiserId: data['organiser_id'] as String? ?? "Unknown",
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _showCreateRoomDialog,
                  child: Text('Create'),
                ),
                ElevatedButton(
                  onPressed: _showJoinRoomDialog,
                  child: Text('Join'),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
