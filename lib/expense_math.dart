import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseMath {
  final String roomId;

  ExpenseMath({required this.roomId});

  Future<List<TextSpan>> calculateExpenses() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('rooms').doc(roomId).collection('expenses')
        .get();

    Map<String, double> balances = {};
    double totalExpense = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double amount = (data['amount'] as num).toDouble();
      Map<String, double> payerName = (data['payerName'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
      List<dynamic> splitWith = data['splitWith'];

      totalExpense += amount;
      double splitAmount = amount / splitWith.length;

      splitWith.forEach((member) {
        balances[member as String] = (balances[member] ?? 0.0) - splitAmount;
      });

      payerName.forEach((key, value) {
        balances[key] = (balances[key] ?? 0.0) + value;
      });
    }

    List<TextSpan> resultSpans = [
      TextSpan(text: 'Total Expense ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black,fontSize: 19)),
      TextSpan(text: 'is ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black)),
      TextSpan(text: '₹${totalExpense.toStringAsFixed(2)}\n\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black,fontSize: 18))
    ];

    Map<String, double> netOwes = resolveBalances(balances);

    netOwes.forEach((key, value) {
      if (value > 0) {

        var parts = key.split(' to ');
        if (parts.length == 2) {
          // Create three TextSpan objects with specific styles
          var payerSpan = TextSpan(text: parts[0], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red));  // Customize as needed
          var toSpan = TextSpan(text: ' to ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black));
          var receiverSpan = TextSpan(text: parts[1], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green));  // Customize as needed

          // Add these spans to the resultSpans list
          resultSpans.addAll([payerSpan, toSpan, receiverSpan]);
        }
        resultSpans.add(TextSpan(text: ' owes ', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black)));
        resultSpans.add(TextSpan(text: '₹${value.toStringAsFixed(2)}\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)));
      }
    });

    return resultSpans;
  }

  Map<String, double> resolveBalances(Map<String, double> balances) {
    // Filter out self-owing cases and normalize net balances
    Map<String, double> result = {};
    balances.forEach((key, value) {
      if (value > 0) {
        result[key] = value;
      }
    });

    // Simplify debt relationships
    Map<String, double> netBalances = {};
    balances.forEach((payer, amount) {
      if (amount < 0) {
        double debt = -amount; // Use -amount safely since it's guaranteed not to be null here
        balances.forEach((receiver, credit) {
          if (credit > 0 && payer != receiver) {
            double payment = (debt < credit) ? debt : credit;
            String transactionKey = "$payer to $receiver";
            netBalances[transactionKey] = (netBalances[transactionKey] ?? 0) + payment;
            balances[receiver] = (balances[receiver] ?? 0) - payment; // Ensure null safety with default value
            debt -= payment;
            if (debt <= 0) return;
          }
        });
      }
    });

    return netBalances;
  }

}


class ExpenseResultsPage extends StatelessWidget {
  final String roomId;

  ExpenseResultsPage({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Expense Results")),
      body: FutureBuilder<List<TextSpan>>(
        future: ExpenseMath(roomId: roomId).calculateExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          if (snapshot.hasData) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.black), // Default text style
                  children: snapshot.data!,
                ),
              ),
            );
          } else {
            return Text("No data calculated");
          }
        },
      ),
    );
  }
}
