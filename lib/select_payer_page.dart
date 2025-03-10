import 'package:flutter/material.dart';
import 'expense_members_backend.dart';
import 'multiple_paid_page.dart';

class SelectPayerPage extends StatefulWidget {
  final String roomId;
  final double totalAmount;  // Add this line

  SelectPayerPage({required this.roomId, required this.totalAmount});  // Include totalAmount here

  @override
  _SelectPayerPageState createState() => _SelectPayerPageState();
}

class _SelectPayerPageState extends State<SelectPayerPage> {
  List<User> members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    var fetchedMembers = await ExpenseBackend.fetchRoomMembers(widget.roomId);
    setState(() {
      members = fetchedMembers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Payer"),
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(members[index].name),
            onTap: () => Navigator.pop(context, {members[index].name: widget.totalAmount}),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.group),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MultiplePaidPage(
                      roomId: widget.roomId,
                      members: members,
                      totalAmount: widget.totalAmount
                  )
              )
          ).then((result) {
            if (result != null) {
              Navigator.pop(context, result);
            }
          });
        },
      ),
    );
  }
}
