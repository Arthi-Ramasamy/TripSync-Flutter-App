import 'package:flutter/material.dart';
import 'chatroom_backend.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  ChatRoomPage({required this.roomId, required this.roomName});

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatroomBackend.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = currentUser != null && currentUser.uid == message.senderId;

                    return Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.w300, // Light style for the sender's name
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              message.text,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, // Bold style for the message text
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final text = _messageController.text.trim();
                    if (text.isNotEmpty && currentUser != null) {
                      ChatroomBackend.sendMessage(widget.roomId, text, currentUser.uid, currentUser.displayName ?? 'Unknown');
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
