import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String description;
  final double amount;
  final String payerName;
  final DateTime date;

  Expense({required this.description, required this.amount, required this.payerName, required this.date});

  // Converts an Expense object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'payerName': payerName,
      'date': date
    };
  }

  // Factory method to create an Expense from a Firestore document.
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      description: data['description'],
      amount: data['amount'],
      payerName: data['payerName'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

class ExpenseBackend {
  // Fetches a stream of Expense objects from Firestore, ordered by date.
  static Stream<List<Expense>> fetchExpenses(String roomId) {
    return FirebaseFirestore.instance
        .collection('rooms').doc(roomId).collection('expenses')
        .orderBy('date',
        descending: true) // Ensures that the newest expenses come first.
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => Expense.fromFirestore(doc))
            .toList());
  }

  // Adds an expense to Firestore and handles errors.
  // Adjusted addExpense function to handle multiple payers and splitting
  static Future<void> addExpense({required String roomId, required Map<String,
      double> payers, required List<
      String> splitWith, required Expense expense}) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection(
        'expenses').add({
      ...expense.toMap(),
      'payerName': payers, // Now an object with name and amount
      'splitWith': splitWith, // Array of users with whom the expense is split
    });
  }
}
