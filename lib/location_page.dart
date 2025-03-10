import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class LocationPage extends StatefulWidget {
  final String roomId;

  LocationPage({required this.roomId});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  List<Marker> _markers = [];
  final MapController _mapController = MapController();
  late final Stream<Map<String, dynamic>> _combinedStream;

  // State variables for current center and zoom
  LatLng _currentCenter = LatLng(20.5937, 78.9629);
  double _currentZoom = 5.0;

  @override
  void initState() {
    super.initState();
    _combinedStream = _createCombinedStream();

    // Listen to map position changes
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        setState(() {
          _currentCenter = event.camera.center;
          _currentZoom = event.camera.zoom;
        });
      }
    });
  }

  Stream<Map<String, dynamic>> _createCombinedStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .switchMap((roomSnapshot) {
      if (!roomSnapshot.exists) {
        return Stream.value({'room': null, 'users': {}});
      }

      List<String> memberIds = List<String>.from(roomSnapshot['member_ids'] ?? []);

      List<Stream<MapEntry<String, DocumentSnapshot>>> userStreams = memberIds.map((userId) {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots()
            .map((userSnapshot) => MapEntry(userId, userSnapshot));
      }).toList();

      return CombineLatestStream.list(userStreams).map((userSnapshots) {
        Map<String, DocumentSnapshot> users = Map.fromEntries(userSnapshots);
        return {'room': roomSnapshot, 'users': users};
      });
    });
  }

  List<Marker> _createMarkers(Map<String, dynamic> data) {
    List<Marker> localMarkers = [];

    DocumentSnapshot? roomSnapshot = data['room'];
    Map<String, DocumentSnapshot> users = data['users'];

    if (roomSnapshot == null || !roomSnapshot.exists) {
      return localMarkers;
    }

    users.forEach((userId, userSnapshot) {
      if (userSnapshot.exists) {
        String username = userSnapshot['name'] ?? 'Unknown';
        GeoPoint? location = userSnapshot['location'] as GeoPoint?;

        if (location != null) {
          LatLng latLng = LatLng(location.latitude, location.longitude);
          localMarkers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: latLng,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 40.0, color: Colors.red),
                  Text(username, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }
      }
    });

    return localMarkers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Location'),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!['room'] == null) {
            return Center(child: Text('No room data available'));
          }

          _markers = _createMarkers(snapshot.data!);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
