import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_manager1/chatroom_page.dart';
import 'package:trip_manager1/members_page.dart';
import 'package:trip_manager1/mytrips_page.dart';
import 'package:trip_manager1/announcements_page.dart';
import 'package:trip_manager1/polls_page.dart';
import 'expense_page.dart';// Import PollsPage
import 'feedback.dart';
import 'location_page.dart';
import 'media_page.dart';
import 'itinerary_page.dart';

class DashboardPage extends StatefulWidget {
  final String roomName;
  final String roomCode;
  final String organiserId;

  DashboardPage({
    required this.roomName,
    required this.roomCode,
    required this.organiserId,
  });

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isOrganiser = false;

  @override
  void initState() {
    super.initState();
    checkIfUserIsOrganiser();
    checkAndShowRecentAnnouncement();
    checkAndShowRecentPoll();  // Check for recent polls
  }

  Future<void> checkIfUserIsOrganiser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final memberDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('members')
          .doc(currentUser.uid)
          .get();
      if (memberDoc.exists && memberDoc.data()?['role'] == 'organiser') {
        setState(() {
          isOrganiser = true;
        });
      }
    }
  }

  Future<void> checkAndShowRecentAnnouncement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final announcementsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (announcementsSnapshot.docs.isNotEmpty) {
      final recentAnnouncementDoc = announcementsSnapshot.docs.first;
      final String recentAnnouncementText = recentAnnouncementDoc.data()?['text'] ?? 'No recent announcements';
      final Timestamp recentAnnouncementTimestamp = recentAnnouncementDoc.data()?['timestamp'];

      String lastSeenKey = 'announcement_seen_${widget.roomCode}';
      int lastSeenTimestamp = prefs.getInt(lastSeenKey) ?? 0;

      if (recentAnnouncementTimestamp.seconds > lastSeenTimestamp) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Recent Announcement'),
              content: Text(recentAnnouncementText),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    prefs.setInt(lastSeenKey, recentAnnouncementTimestamp.seconds);
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> checkAndShowRecentPoll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final pollsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('polls')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (pollsSnapshot.docs.isNotEmpty) {
      final recentPollDoc = pollsSnapshot.docs.first;
      final String pollQuestion = recentPollDoc.data()?['question'] ?? 'No recent polls';
      final List<dynamic> options = recentPollDoc.data()?['options'] ?? [];

      String lastVotedKey = 'poll_voted_${recentPollDoc.id}';
      bool hasVoted = prefs.getBool(lastVotedKey) ?? false;

      if (!hasVoted) {
        String selectedOption = ''; // Keep track of the selected option

        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Recent Poll'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pollQuestion),  // Display the poll question
                      SizedBox(height: 20),
                      Column(
                        children: options.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: selectedOption,
                            onChanged: (value) {
                              setState(() {
                                selectedOption = value ?? '';  // Update selected option and refresh UI
                              });
                            },
                            activeColor: Colors.blue,  // Highlight selected option
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () async {
                        if (selectedOption.isNotEmpty) {
                          // Store the username and selected option in the 'votes' field
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .get();

                          final username = userDoc.data()?['name'] ?? currentUser.uid;

                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .collection('polls')
                              .doc(recentPollDoc.id)
                              .update({
                            'votes.$username': selectedOption,
                          });

                          // Mark as voted
                          prefs.setBool(lastVotedKey, true);
                        }

                        Navigator.of(context).pop();
                      },
                      child: Text('Submit Vote'),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => handleMenuSelection(value),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Room Code',
                child: Text('Room Code: ${widget.roomCode}'),
              ),
              PopupMenuItem<String>(
                value: 'Members',
                child: Text('Members'),
              ),
              PopupMenuItem<String>(
                value: 'Leave',
                child: Text('Leave'),
              ),
              if (isOrganiser)
                PopupMenuItem<String>(
                  value: 'Delete',
                  child: Text('Delete'),
                ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          children: [
            DashboardButton(
              icon: Icons.location_on,
              label: 'Location',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPage(roomId: widget.roomCode),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.attach_money,
              label: 'Expense',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpensePage(roomId: widget.roomCode),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.list_alt,
              label: 'Itinerary',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItineraryPage(
                      roomCode: widget.roomCode,   // Pass roomCode to ItineraryPage
                      organiserId: widget.organiserId,  // Pass organiserId to ItineraryPage
                    ),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.chat,
              label: 'Chatroom',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomPage(
                      roomId: widget.roomCode,
                      roomName: widget.roomName,
                    ),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.announcement,
              label: 'Announcements',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementsPage(
                      roomId: widget.roomCode,
                    ),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.poll,
              label: 'Polls',  // Added Polls button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PollsPage(
                      roomCode: widget.roomCode,  // Corrected parameter name
                      isOrganizer: isOrganiser,  // Corrected parameter name
                    ),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.photo_library,  // You can use any icon that represents media
              label: 'Media',  // The label for the button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MediaPage(
                      roomCode: widget.roomCode,
                    ),
                  ),
                );
              },
            ),
            DashboardButton(
              icon: Icons.feedback,
              label: 'Feedback',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackPage(
                      roomCode: widget.roomCode,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void handleMenuSelection(String value) {
    switch (value) {
      case 'Room Code':
        Clipboard.setData(ClipboardData(text: widget.roomCode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room code copied to clipboard')),
        );
        break;
      case 'Members':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MembersPage(
              roomCode: widget.roomCode,
              organiserId: widget.organiserId,
            ),
          ),
        );
        break;
      case 'Leave':
        showConfirmDialog('Leave', 'Are you sure you want to leave this room?', leaveRoom);
        break;
      case 'Delete':
        showConfirmDialog('Delete', 'Are you sure you want to delete this room?', deleteRoom);
        break;
    }
  }

  void showConfirmDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> leaveRoom() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Remove user from the members collection
      await FirebaseFirestore.instance
          .collection('rooms').doc(widget.roomCode)
          .collection('members').doc(currentUser.uid).delete();

      // Optionally, remove user from member_ids array if it exists in your Firestore data model
      await FirebaseFirestore.instance
          .collection('rooms').doc(widget.roomCode)
          .update({
        'member_ids': FieldValue.arrayRemove([currentUser.uid])
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MyTripsPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> deleteRoom() async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .delete();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyTripsPage()),
          (Route<dynamic> route) => false,
    );
  }
}

class DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  DashboardButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40.0),
          SizedBox(height: 8.0),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
