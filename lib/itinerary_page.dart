import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ItineraryPage extends StatefulWidget {
  final String roomCode;
  final String organiserId;

  ItineraryPage({required this.roomCode, required this.organiserId});

  @override
  _ItineraryPageState createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  bool isOrganizer = false;
  int selectedDay = 1;
  List<Map<String, dynamic>> days = []; // List of days
  Map<int, List<Map<String, dynamic>>> itinerary = {}; // Itinerary for each day
  Map<int, DateTime> dayDates = {}; // Date for each day

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchItinerary();
  }
   // Already imported

  Future<void> generateItineraryPDF() async {
    final pdf = pw.Document();

    // Add a cover page or header to the PDF
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          List<pw.Widget> pdfContent = [];

          // Add a header to the PDF
          pdfContent.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                'Itinerary',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );

          // Iterate through each day in the itinerary
          itinerary.forEach((day, events) {
            pdfContent.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Day $day',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  if (dayDates[day] != null) // Add date if available
                    pw.Text('Date: ${DateFormat('MMM d, yyyy').format(dayDates[day]!)}'),
                  pw.SizedBox(height: 8), // Spacing

                  // Iterate through the events for the day
                  ...events.map((event) {
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Event: ${event['name'] ?? 'Unnamed Event'}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Time: ${event['time'] ?? 'No time specified'}'),
                        pw.Text('Description: ${event['description'] ?? 'No description'}'),
                        pw.SizedBox(height: 8), // Spacing between events
                      ],
                    );
                  }).toList(),

                  pw.Divider(), // Divider between days
                ],
              ),
            );
          });

          return pdfContent;
        },
      ),
    );

    // Save the PDF and download it using the Printing package
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Get the user’s role from Firestore
      final memberDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('members')
          .doc(currentUser.uid)
          .get();
      if (memberDoc.exists && memberDoc.data()?['role'] == 'organiser') {
        setState(() {
          isOrganizer = true;
        });
      }
    }
  }

  Future<void> fetchItinerary() async {
    final itinerarySnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('itinerary')
        .orderBy('day')
        .get();

    Map<int, List<Map<String, dynamic>>> fetchedItinerary = {};
    List<Map<String, dynamic>> fetchedDays = [];
    Map<int, DateTime> fetchedDayDates = {};

    for (var doc in itinerarySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      int day = data['day'];
      DateTime? date = (data['date'] as Timestamp?)?.toDate();
      data['id'] = doc.id; // Save document ID for editing/deleting

      if (!fetchedItinerary.containsKey(day)) {
        fetchedItinerary[day] = [];
        fetchedDays.add({'day': day});
        if (date != null) {
          fetchedDayDates[day] = date;
        }
      }

      fetchedItinerary[day]?.add(data);
    }

    setState(() {
      itinerary = fetchedItinerary;
      days = fetchedDays;
      dayDates = fetchedDayDates;
      if (days.isNotEmpty) {
        selectedDay = days.first['day'];
      }
    });
  }

  // Select day
  void selectDay(int day) {
    setState(() {
      selectedDay = day;
    });
  }

  // Add new day with date selection
  Future<void> addNewDay() async {
    int newDay = (days.isNotEmpty) ? days.last['day'] + 1 : 1;
    DateTime? selectedDate = await selectDate();

    if (selectedDate != null) {
      // Save new day to Firestore
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('itinerary')
          .add({
        'day': newDay,
        'date': selectedDate, // Save the selected date
      });

      setState(() {
        days.add({'day': newDay});
        dayDates[newDay] = selectedDate;
        itinerary[newDay] = [];
        selectDay(newDay);
      });
    }
  }

  // Select a date using date picker
  Future<DateTime?> selectDate() async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
  }

  // Update the date for an existing day
  Future<void> updateDayDate(int day) async {
    DateTime? pickedDate = await selectDate();
    if (pickedDate != null) {
      setState(() {
        dayDates[day] = pickedDate;
      });

      // Update the date in Firestore
      var dayDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('itinerary')
          .where('day', isEqualTo: day)
          .get();

      if (dayDoc.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .collection('itinerary')
            .doc(dayDoc.docs.first.id)
            .update({'date': pickedDate});
      }
    }
  }

  // Build day selector with date
  Widget buildDaySelector(int day) {
    DateTime? date = dayDates[day];
    String formattedDate = date != null ? DateFormat('MMM d').format(date) : 'Pick Date';

    return Column(
      children: [
        Text('Day $day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate),
            if (isOrganizer)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => updateDayDate(day), // Update day date
              ),
          ],
        ),
      ],
    );
  }

  // Build day itinerary
  Widget buildItineraryDay(int day) {
    List<Map<String, dynamic>> events = itinerary[day] ?? [];
    return Column(
      children: [
        buildDaySelector(day), // Show day and date picker
        for (var event in events)
          ListTile(
            title: Text(event['name'] ?? 'Unnamed Event'),
            subtitle: Text('${event['time'] ?? 'No time specified'} - ${event['description'] ?? 'No description'}'),
            trailing: isOrganizer
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => showEditEventDialog(event), // Edit functionality
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteEvent(day, event['id']),
                ),
              ],
            )
                : null,
          ),
        if (isOrganizer)
          ElevatedButton(
            onPressed: () => showAddEventDialog(day),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Add Event'),
                Icon(Icons.add),
              ],
            ),
          ),
      ],
    );
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerary'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              generateItineraryPDF();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Selector Row with Add Day Icon
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () => selectDay(days[index]['day']),
                          child: Text(
                            'Day ${days[index]['day']}',
                            style: TextStyle(
                              color: selectedDay == days[index]['day']
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedDay == days[index]['day']
                                ? Colors.blueAccent
                                : Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Add Day Button (Only visible to Organizer)
                if (isOrganizer)
                  IconButton(
                    icon: Icon(Icons.add_circle, size: 35, color: Colors.blueAccent),
                    onPressed: addNewDay,
                  ),
              ],
            ),
          ),
          Expanded(
            child: buildItineraryDay(selectedDay),
          ),
        ],
      ),
    );
  }

  // Add a new event to Firestore and update state
  void addEventToItinerary(int day, TimeOfDay time, String name, String description) async {
    final newEvent = {
      'time': time.format(context),
      'name': name,
      'description': description,
      'day': day,
    };

    final docRef = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('itinerary')
        .add(newEvent);

    setState(() {
      itinerary[day]?.add({...newEvent, 'id': docRef.id});
    });
  }

  // Functionality for adding a new event
  void showAddEventDialog(int day) {
    String eventName = '';
    String eventDescription = '';
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Event Name'),
                onChanged: (value) {
                  eventName = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  eventDescription = value;
                },
              ),
              SizedBox(height: 20),
              Text('Time: ${selectedTime.format(context)}'),
              ElevatedButton(
                child: Text('Pick Time'),
                onPressed: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addEventToItinerary(day, selectedTime, eventName, eventDescription);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Functionality to edit an event
  void showEditEventDialog(Map<String, dynamic> event) {
    String eventName = event['name'];
    String eventDescription = event['description'];
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse(event['time'].split(":")[0]),
      minute: int.parse(event['time'].split(":")[1].split(" ")[0]),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: eventName,
                decoration: InputDecoration(labelText: 'Event Name'),
                onChanged: (value) {
                  eventName = value;
                },
              ),
              TextFormField(
                initialValue: eventDescription,
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  eventDescription = value;
                },
              ),
              SizedBox(height: 20),
              Text('Time: ${selectedTime.format(context)}'),
              ElevatedButton(
                child: Text('Pick Time'),
                onPressed: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                updateEvent(event['id'], selectedTime, eventName, eventDescription);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Update an event in Firestore
  void updateEvent(String eventId, TimeOfDay time, String name, String description) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('itinerary')
        .doc(eventId)
        .update({
      'time': time.format(context),
      'name': name,
      'description': description,
    });

    setState(() {
      itinerary[selectedDay] = itinerary[selectedDay]!.map((event) {
        if (event['id'] == eventId) {
          event['time'] = time.format(context);
          event['name'] = name;
          event['description'] = description;
        }
        return event;
      }).toList();
    });
  }

  // Delete an event from Firestore and update state
  void deleteEvent(int day, String eventId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('itinerary')
        .doc(eventId)
        .delete();

    setState(() {
      itinerary[day]?.removeWhere((event) => event['id'] == eventId);
    });
  }
}
