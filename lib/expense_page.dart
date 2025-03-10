import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_expense_page.dart';
import 'expense_math.dart'; // Make sure this import points to the correct file

class Expense {
  final String id;
  final String description;
  final double amount;
  final Map<String, double> payerName;
  final DateTime date;
  final List<String> splitWith;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.payerName,
    required this.date,
    required this.splitWith,
  });

  factory Expense.fromDocument(DocumentSnapshot doc) {
    return Expense(
      id: doc.id,
      description: doc['description'] ?? "",
      amount: doc['amount']?.toDouble() ?? 0.0,
      payerName: Map<String, double>.from(doc['payerName']),
      date: (doc['date'] as Timestamp).toDate(),
      splitWith: List<String>.from(doc['splitWith']),
    );
  }
}

class ExpensePage extends StatefulWidget {
  final String roomId;

  ExpensePage({required this.roomId});

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final DateFormat _dateFormatter = DateFormat('MMM\ndd');
  final DateFormat _timeFormatter = DateFormat('hh:mm a');
  final Set<String> _selectedExpenses = Set(); // Track selected expenses

  Stream<List<Expense>> fetchExpenses() {
    return FirebaseFirestore.instance
        .collection('rooms').doc(widget.roomId).collection('expenses')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Expense.fromDocument(doc)).toList()
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedExpenses.contains(id)) {
        _selectedExpenses.remove(id);
      } else {
        _selectedExpenses.add(id);
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete these expenses?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                setState(() => _selectedExpenses.clear()); // Clear selection on cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog before deleting
                _deleteSelectedExpenses();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedExpenses() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    _selectedExpenses.forEach((id) {
      batch.delete(FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('expenses').doc(id));
    });
    await batch.commit();
    setState(() => _selectedExpenses.clear()); // Clear selection after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expenses"),
        actions: _selectedExpenses.isNotEmpty ? [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          )
        ] : [],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: fetchExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No expenses found."));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Expense expense = snapshot.data![index];
              bool isSelected = _selectedExpenses.contains(expense.id);
              return InkWell(
                onLongPress: () => _toggleSelection(expense.id),
                onTap: () {
                  if (_selectedExpenses.isNotEmpty) {
                    _toggleSelection(expense.id);
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ExpenseDetailPage(expense: expense)
                    ));
                  }
                },
                child: Card(
                  color: isSelected ? Colors.grey[300] : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Text(
                            _dateFormatter.format(expense.date),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _timeFormatter.format(expense.date),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(expense.description
                              ,style: TextStyle(fontSize: 16),),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddExpensePage(roomId: widget.roomId)
          ));
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: _selectedExpenses.isNotEmpty ? null : ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ExpenseResultsPage(roomId: widget.roomId,)
          ));
        },
        child: Text("Calculate"),
      ),
    );
  }
}

// Expense Detail Page
class ExpenseDetailPage extends StatelessWidget {
  final Expense expense;

  ExpenseDetailPage({required this.expense});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatter = DateFormat('MMM dd, yyyy');
    final DateFormat timeFormatter = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text("Expense Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Description: ${expense.description}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Amount: ₹${expense.amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Date: ${dateFormatter.format(expense.date)} at ${timeFormatter.format(expense.date)}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Paid by:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...expense.payerName.entries.map((entry) =>
                Text("${entry.key}: ₹${entry.value.toStringAsFixed(2)}", style: TextStyle(fontSize: 16))
            ),
            SizedBox(height: 10),
            Text("Split with:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...expense.splitWith.map((name) =>
                Text(name, style: TextStyle(fontSize: 16))
            ),
          ],
        ),
      ),
    );
  }
}
