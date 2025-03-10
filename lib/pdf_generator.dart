import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateItineraryPDF(String roomCode) async {
    final itinerarySnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .collection('itinerary')
        .orderBy('day')
        .get();

    // Creating the PDF document
    final pdf = pw.Document();

    // Adding content to the PDF
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text('Trip Itinerary', style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 20),
          ...itinerarySnapshot.docs.map((doc) {
            final data = doc.data();
            final day = data['day'];
            final date = (data['date'] as Timestamp?)?.toDate();
            final formattedDate =
            date != null ? DateFormat('MMM d, yyyy').format(date) : 'No Date';

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Day $day - $formattedDate',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...data['events'].map<pw.Widget>((event) {
                  final eventName = event['name'] ?? 'Unnamed Event';
                  final eventTime = event['time'] ?? 'No time specified';
                  final eventDescription = event['description'] ?? 'No description';

                  return pw.Padding(
                    padding: pw.EdgeInsets.symmetric(vertical: 5),
                    child: pw.Text(
                      '$eventTime - $eventName: $eventDescription',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                pw.Divider(),
              ],
            );
          }).toList(),
        ],
      ),
    );

    // Saving or sharing the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

class ItineraryPage extends StatefulWidget {
  final String roomCode;

  ItineraryPage({required this.roomCode});

  @override
  _ItineraryPageState createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerary'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              PdfGenerator.generateItineraryPDF(widget.roomCode);
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Itinerary content here'),
      ),
    );
  }
}
