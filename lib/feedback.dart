import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'feedback_service.dart';
import 'emoji_selector.dart';

class FeedbackPage extends StatefulWidget {
  final String roomCode;

  FeedbackPage({required this.roomCode});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();
  String? _selectedEmoji;
  bool _isOrganizer = false;
  bool _hasSubmittedFeedback = false;

  @override
  void initState() {
    super.initState();
    _initPage();
    _feedbackController.addListener(_updateSubmitButtonState);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _initPage() async {
    // Check if the user is an organizer and if they have already submitted feedback
    _isOrganizer = await FeedbackService.isOrganizer(widget.roomCode);
    _hasSubmittedFeedback = await FeedbackService.hasSubmittedFeedback(widget.roomCode);
    setState(() {});
  }

  void _submitFeedback() async {
    final feedbackText = _feedbackController.text;

    if (_selectedEmoji == null || feedbackText.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select a rating and enter feedback',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Submit feedback using the backend service
    bool success = await FeedbackService.submitFeedback(
      roomCode: widget.roomCode,
      feedback: feedbackText,
      emoji: _selectedEmoji!,
    );

    if (success) {
      Fluttertoast.showToast(
        msg: 'Feedback submitted!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      _feedbackController.clear();
      setState(() {
        _selectedEmoji = null;
        _hasSubmittedFeedback = true;
      });
    }
  }

  void _updateSubmitButtonState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
        actions: _isOrganizer
            ? [IconButton(icon: Icon(Icons.analytics), onPressed: () {/* View all feedback logic */})]
            : [IconButton(icon: Icon(Icons.person), onPressed: () {/* View user feedback logic */})],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            EmojiSelector(
              selectedEmoji: _selectedEmoji,
              onEmojiSelected: (emoji) => setState(() => _selectedEmoji = emoji),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                labelText: 'Enter your feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _hasSubmittedFeedback || _selectedEmoji == null || _feedbackController.text.isEmpty
                  ? null
                  : _submitFeedback,
              child: Text(_hasSubmittedFeedback ? 'Feedback Submitted' : 'Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
