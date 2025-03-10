import 'package:flutter/material.dart';
import 'expense_members_backend.dart';

class MultiplePaidPage extends StatefulWidget {
  final String roomId;
  final List<User> members;
  final double totalAmount;

  MultiplePaidPage({required this.roomId, required this.members, required this.totalAmount});

  @override
  _MultiplePaidPageState createState() => _MultiplePaidPageState();
}

class _MultiplePaidPageState extends State<MultiplePaidPage> {
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    widget.members.forEach((member) {
      controllers[member.name] = TextEditingController(text: '0');
    });
  }

  void finalizePayments() {
    double sum = controllers.values.fold(0.0, (prev, controller) => prev + (double.tryParse(controller.text) ?? 0.0));
    // Use a small tolerance for floating point comparison
    double tolerance = 0.01;

    if ((widget.totalAmount - sum).abs() > tolerance) {
      // Show error if the amounts do not match within the tolerance
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Sorry"),
          content: Text("Amount does not match. Expected: ${widget.totalAmount}, Entered: $sum"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      Map<String, double> payments = {};
      controllers.forEach((name, controller) {
        double amount = double.tryParse(controller.text) ?? 0;
        if (amount > 0) payments[name] = amount;
      });
      Navigator.pop(context, payments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Multiple Users Paid")),
      body: ListView.builder(
        itemCount: widget.members.length,
        itemBuilder: (context, index) {
          var user = widget.members[index];
          return ListTile(
            title: Text(user.name),
            trailing: SizedBox(
              width: 100,
              child: TextField(
                controller: controllers[user.name],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount ₹'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: finalizePayments,
      ),
    );
  }
}
