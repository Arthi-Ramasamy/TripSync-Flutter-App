import 'package:flutter/material.dart';
import 'expense_members_backend.dart';  // Make sure this import points to the correct file for ExpenseBackend

class SplitWithPage extends StatefulWidget {
  final String roomId;

  SplitWithPage({required this.roomId});

  @override
  _SplitWithPageState createState() => _SplitWithPageState();
}

class _SplitWithPageState extends State<SplitWithPage> {
  List<User> members = [];
  Map<String, bool> selectedMembers = {};
  bool _selectAll = false;  // To track the select all toggle state

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    var fetchedMembers = await ExpenseBackend.fetchRoomMembers(widget.roomId);
    setState(() {
      members = fetchedMembers;
      // Initialize all members as not selected initially
      selectedMembers = { for (var member in members) member.name: false };
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;  // Toggle the select all state
      for (var member in members) {
        selectedMembers[member.name] = _selectAll;  // Set all to the toggle state
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Split With"),
        actions: <Widget>[
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              "All",
              style: TextStyle(
                  color: Colors.black,  // Ensure the text color contrasts with the AppBar
                  fontWeight: FontWeight.bold,
                  fontSize: 17
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: members.map((member) {
          return CheckboxListTile(
            title: Text(member.name),
            value: selectedMembers[member.name],
            onChanged: (bool? value) {
              setState(() {
                selectedMembers[member.name] = value!;
              });
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.check),
          onPressed: () {
            Navigator.pop(context, selectedMembers.entries.where((entry) => entry.value).map((e) => e.key).toList());
          }
      ),
    );
  }
}
