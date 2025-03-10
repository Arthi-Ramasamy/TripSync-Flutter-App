import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollsPage extends StatefulWidget {
  final String roomCode;
  final bool isOrganizer;

  PollsPage({required this.roomCode, required this.isOrganizer});

  @override
  _PollsPageState createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  Set<String> selectedPolls = {};  // Holds the IDs of selected polls
  bool selectionMode = false;  // Indicates if selection mode is active

  @override
  void dispose() {
    _questionController.dispose();
    _optionControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void postPoll() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _optionControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a question and at least one option')),
      );
      return;
    }

    final options = _optionControllers.map((controller) => controller.text.trim()).toList();
    final pollData = {
      'question': question,
      'options': options,
      'votes': {},  // Votes will be stored as {username: option}
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('polls')
        .add(pollData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Poll posted successfully')),
    );

    _questionController.clear();
    _optionControllers.forEach((controller) => controller.clear());
  }

  void voteOnPoll(String pollId, String option) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final username = userDoc.data()?['name'] ?? 'Anonymous';

      final pollDoc = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('polls')
          .doc(pollId);

      pollDoc.update({
        'votes.$username': option,  // Store {username: option} in the 'votes' map
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your vote has been submitted')),
      );
    }
  }

  // Toggle selection of a poll
  void toggleSelection(String pollId) {
    setState(() {
      if (selectedPolls.contains(pollId)) {
        selectedPolls.remove(pollId);
      } else {
        selectedPolls.add(pollId);
      }

      if (selectedPolls.isEmpty) {
        selectionMode = false;  // Exit selection mode if no polls are selected
      }
    });
  }

  // Delete selected polls from Firebase
  void deleteSelectedPolls() async {
    final pollsCollection = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('polls');

    for (String pollId in selectedPolls) {
      await pollsCollection.doc(pollId).delete();
    }

    // Clear selection after deletion
    setState(() {
      selectedPolls.clear();
      selectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected polls deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Polls'),
        actions: selectionMode
            ? [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: deleteSelectedPolls,  // Delete selected polls
          ),
        ]
            : [],
      ),
      body: Column(
        children: [
          if (widget.isOrganizer) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Poll Question',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ..._optionControllers.map((controller) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Poll Option',
                    border: OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: addOption,
                    child: Text('Add Option'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: postPoll,
                    child: Text('Post Poll'),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .collection('polls')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final polls = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: polls.length,
                  itemBuilder: (context, index) {
                    final poll = polls[index];
                    final pollId = poll.id;
                    final pollQuestion = poll['question'];
                    final pollOptions = List<String>.from(poll['options']);
                    final votes = Map<String, dynamic>.from(poll['votes']);
                    final isSelected = selectedPolls.contains(pollId);

                    return GestureDetector(
                      onLongPress: () {
                        if (widget.isOrganizer) {
                          setState(() {
                            selectionMode = true;  // Enter selection mode
                            toggleSelection(pollId);
                          });
                        }
                      },
                      onTap: selectionMode
                          ? () {
                        toggleSelection(pollId);  // Toggle poll selection
                      }
                          : null,
                      child: Card(
                        color: isSelected ? Colors.grey[300] : null,  // Highlight selected polls
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pollQuestion,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ...pollOptions.map((option) {
                                final voteCount = votes.values
                                    .where((vote) => vote == option)
                                    .length;

                                return ListTile(
                                  title: Text(option),
                                  subtitle: Text('Votes: $voteCount'),
                                  trailing: ElevatedButton(
                                    onPressed: () => voteOnPoll(pollId, option),
                                    child: Text('Vote'),
                                  ),
                                );
                              }).toList(),
                              // Display voters if available
                              if (votes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    'Users who voted:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (votes.isNotEmpty)
                                DropdownButton<String>(
                                  isExpanded: true,
                                  items: votes.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text('${entry.key} voted for ${entry.value}'),
                                    );
                                  }).toList(),
                                  onChanged: (_) {},
                                  hint: Text('View voters'),
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
          ),
        ],
      ),
    );
  }
}
