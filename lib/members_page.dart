import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersPage extends StatefulWidget {
  final String roomCode;
  final String organiserId;

  MembersPage({required this.roomCode, required this.organiserId});

  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  bool isLoading = true;
  bool isOrganiser = false;

  List<Member> members = [];

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    setState(() {
      isLoading = true;
    });

    // Check if the current user is an organizer
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot memberSnapshot = await FirebaseFirestore.instance
          .collection('rooms').doc(widget.roomCode)
          .collection('members').doc(currentUser.uid).get();
      var data = memberSnapshot.data() as Map<String, dynamic>?;  // Correctly cast the data
      if (data != null && data['role'] == 'organiser') {
        isOrganiser = true;
      }
    }

    // Fetch all members
    QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
        .collection('rooms').doc(widget.roomCode)
        .collection('members').get();

    List<Member> fetchedMembers = [];
    for (var memberDoc in membersSnapshot.docs) {
      var memberData = memberDoc.data() as Map<String, dynamic>;  // Correct casting
      var userData = await FirebaseFirestore.instance.collection('users').doc(memberDoc.id).get();
      var user = userData.data() as Map<String, dynamic>?;  // Correct casting
      if (user != null) {
        fetchedMembers.add(Member(
          id: memberDoc.id,
          name: user['name'] ?? 'No name',
          role: memberData['role'],
        ));
      }
    }

    // Sorting members: first by role (organizers at top), then by name
    fetchedMembers.sort((a, b) {
      if (a.role == b.role) {
        return a.name.compareTo(b.name);
      }
      return a.role == 'organiser' ? -1 : 1;
    });

    setState(() {
      members = fetchedMembers;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Members"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: members.map((member) => buildMemberTile(member)).toList(),
      ),
    );
  }

  Widget buildMemberTile(Member member) {
    return ListTile(
      title: Text(member.name),
      trailing: Icon(member.role == 'organiser' ? Icons.star : Icons.person),
      tileColor: member.role == 'organiser' ? Colors.pink.shade50 : Colors.blue.shade50,
      onTap: isOrganiser ? () => showRoleChangeOptions(context, member.id, member.role == 'organiser') : null,
    );
  }

  void showRoleChangeOptions(BuildContext context, String memberId, bool isOrganiser) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            if (isOrganiser)
              ListTile(
                leading: Icon(Icons.arrow_downward),
                title: Text('Depromote to Participant'),
                onTap: () async {
                  if (await confirmLastOrganiser()) {
                    updateMemberRole(memberId, false);
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot depromote the last organiser.")));
                  }
                },
              ),
            if (!isOrganiser)
              ListTile(
                leading: Icon(Icons.arrow_upward),
                title: Text('Promote to Organiser'),
                onTap: () {
                  updateMemberRole(memberId, true);
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }

  Future<bool> confirmLastOrganiser() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('rooms').doc(widget.roomCode)
        .collection('members').where('role', isEqualTo: 'organiser').get();
    return snapshot.docs.length > 1;  // More than one organiser exists
  }

  void updateMemberRole(String memberId, bool makeOrganiser) {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode)
        .collection('members').doc(memberId)
        .update({'role': makeOrganiser ? 'organiser' : 'participant'});
  }
}

class Member {
  String id;
  String name;
  String role;

  Member({required this.id, required this.name, required this.role});
}
