import 'package:flutter/material.dart';
import 'package:trip_manager1/expense_backend.dart' as expenseBackend;  // Alias this import
import 'package:trip_manager1/expense_members_backend.dart' as membersBackend; // Alias this import if needed
import 'select_payer_page.dart';
import 'multiple_paid_page.dart';
import 'split_with_page.dart';

class AddExpensePage extends StatefulWidget {
  final String roomId;

  AddExpensePage({required this.roomId, Key? key}) : super(key: key);

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  Map<String, double> _payers = {};
  String _payersDisplay = "Select payer";
  List<String> _splitWith = [];

  void _selectPayer() async {
    double totalAmount = double.tryParse(_amountController.text) ?? 0;
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectPayerPage(roomId: widget.roomId, totalAmount: totalAmount)
        )
    );
    if (result != null) {
      setState(() {
        _payers = result;
        _payersDisplay = result.keys.join(", ");
      });
    }
  }

  void _chooseSplit() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SplitWithPage(roomId: widget.roomId)
        )
    );
    if (result != null) {
      setState(() {
        _splitWith = List<String>.from(result);
      });
    }
  }

  void _addExpense() {
    if (_descriptionController.text.isNotEmpty && _amountController.text.isNotEmpty && _payers.isNotEmpty) {
      double totalAmount = _payers.values.fold(0, (previous, current) => previous + current);
      expenseBackend.ExpenseBackend.addExpense(
          roomId: widget.roomId,
          payers: _payers,
          splitWith: _splitWith,
          expense: expenseBackend.Expense(
              description: _descriptionController.text,
              amount: totalAmount,
              payerName: _payersDisplay,
              date: DateTime.now()
          )
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Expense"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0), // Added padding for better UI
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Aligns text fields to the start
          children: <Widget>[
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(), // Adds border to text field
              ),
              textInputAction: TextInputAction.next, // Adds a next button to the keyboard
            ),
            SizedBox(height: 20), // Adds space between fields
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(), // Adds border to text field
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done, // Changes the keyboard action to done
            ),
            ListTile(
              title: Text("Paid by: $_payersDisplay"),
              onTap: _selectPayer,
            ),
            ListTile(
              title: Text("Split with: ${_splitWith.join(", ")}"),
              onTap: _chooseSplit,
            ),
            Center(
              child: ElevatedButton(
                onPressed: _addExpense,
                child: Text("Add Expense"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
