import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import package for date formatting
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trip_manager1/announcements_backend.dart';

class AnnouncementsPage extends StatefulWidget {
  final String roomId;

  AnnouncementsPage({required this.roomId});

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _announcementController = TextEditingController();
  bool isOrganiser = false;
  Set<String> selectedAnnouncements = {}; // Track selected announcements for deletion

  @override
  void initState() {
    super.initState();
    checkIfUserIsOrganiser();
  }

  Future<void> checkIfUserIsOrganiser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      isOrganiser = await AnnouncementsBackend.isUserOrganiser(widget.roomId, currentUser.uid);
      setState(() {});
    }
  }

  void toggleSelection(String announcementId) {
    setState(() {
      if (selectedAnnouncements.contains(announcementId)) {
        selectedAnnouncements.remove(announcementId);
      } else {
        selectedAnnouncements.add(announcementId);
      }
    });
  }

  void deleteSelectedAnnouncements() {
    for (String announcementId in selectedAnnouncements) {
      AnnouncementsBackend.deleteAnnouncement(widget.roomId, announcementId);
    }
    setState(() {
      selectedAnnouncements.clear(); // Clear selections after deletion
    });
  }

  String getOrdinal(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
        actions: [
          if (isOrganiser && selectedAnnouncements.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: deleteSelectedAnnouncements,
              tooltip: 'Delete selected announcements',
            ),
        ],
      ),
      body: Column(
        children: [
          if (isOrganiser)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _announcementController,
                    decoration: InputDecoration(
                      hintText: 'Post an announcement...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final text = _announcementController.text.trim();
                      if (text.isNotEmpty) {
                        AnnouncementsBackend.postAnnouncement(widget.roomId, text);
                        _announcementController.clear();
                      }
                    },
                    child: Text('Post Announcement'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Announcement>>(
              stream: AnnouncementsBackend.getAnnouncements(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading announcements'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final announcements = snapshot.data!;
                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];

                    // Date Formatting
                    final DateTime date = announcement.timestamp;
                    final String day = DateFormat('d').format(date);
                    final String monthYear = DateFormat('MMMM yyyy').format(date);
                    final String time = DateFormat('h:mm a').format(date);
                    final String formattedDate = '$day${getOrdinal(date.day)} $monthYear';

                    return GestureDetector(
                      onLongPress: isOrganiser
                          ? () => toggleSelection(announcement.id)
                          : null, // Only allow long press for organizers
                      child: Container(
                        color: selectedAnnouncements.contains(announcement.id)
                            ? Colors.blue.withOpacity(0.2) // Highlight selected announcement
                            : Colors.transparent,
                        child: ListTile(
                          title: Text(
                            announcement.text,
                            style: TextStyle(
                              fontWeight: selectedAnnouncements.contains(announcement.id)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$formattedDate,$time')
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
