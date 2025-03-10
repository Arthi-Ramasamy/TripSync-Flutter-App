import 'package:flutter/material.dart';

class EmojiSelector extends StatelessWidget {
  final String? selectedEmoji;
  final Function(String) onEmojiSelected;

  final List<Map<String, String>> emojiOptions = [
    {'emoji': '😢', 'label': 'Very Bad'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '😍', 'label': 'Amazing'},
  ];

  EmojiSelector({required this.selectedEmoji, required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16.0,
      children: emojiOptions.map((option) {
        return GestureDetector(
          onTap: () => onEmojiSelected(option['emoji']!),
          child: Column(
            children: [
              Text(
                option['emoji']!,
                style: TextStyle(
                  fontSize: 32.0,
                  decoration: selectedEmoji == option['emoji']
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
              Text(option['label']!),
            ],
          ),
        );
      }).toList(),
    );
  }
}
