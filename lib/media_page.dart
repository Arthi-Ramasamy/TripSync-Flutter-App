import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class MediaPage extends StatefulWidget {
  final String roomCode;

  MediaPage({required this.roomCode});

  @override
  _MediaPageState createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  final ImagePicker _picker = ImagePicker();

  // Step 1: Upload Media (Image or Video)
  Future<void> _uploadMedia(bool isVideo) async {
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    try {
      final File mediaFile = File(file.path);
      final String fileType = isVideo ? 'videos' : 'images';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('rooms/${widget.roomCode}/$fileType/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(mediaFile);

      // Wait for the upload to complete
      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .collection('media')
            .add({
          'url': downloadUrl,
          'type': isVideo ? 'video' : 'image',
          'timestamp': FieldValue.serverTimestamp()
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isVideo ? 'Video uploaded successfully' : 'Image uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload media')),
      );
    }
  }

  // Step 2: Download Media and Save to Gallery
  Future<void> _downloadMedia(String url, String mediaType) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.${mediaType == 'video' ? 'mp4' : 'jpg'}';

      // Download the file and save it to a temporary directory
      final response = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Save the file to the gallery using gallery_saver
      if (mediaType == 'video') {
        await GallerySaver.saveVideo(file.path);
      } else {
        await GallerySaver.saveImage(file.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Media saved to gallery')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download media')),
      );
    }
  }

  // Step 3: Delete Media (for organizers)
  Future<void> _deleteMedia(String docId, String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('media')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Media deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete media')),
      );
    }
  }

  // Step 4: Show Media Preview (Image or Video)
  void _showMediaPreview(String url, String mediaType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(mediaType == 'video' ? 'Video Preview' : 'Image Preview'),
          content: mediaType == 'video'
              ? VideoPlayerWidget(videoUrl: url)
              : Image.network(url),
          actions: [
            TextButton(
              onPressed: () async {
                await _downloadMedia(url, mediaType);
                Navigator.of(context).pop();
              },
              child: Text('Download'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Step 5: Display List of Uploaded Media
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media Space'),
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: () => _uploadMedia(false), // Upload image
          ),
          IconButton(
            icon: Icon(Icons.video_library),
            onPressed: () => _uploadMedia(true), // Upload video
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .collection('media')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No media available.'));
          }

          final mediaDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: mediaDocs.length,
            itemBuilder: (context, index) {
              final mediaData = mediaDocs[index].data() as Map<String, dynamic>;
              final mediaUrl = mediaData['url'] ?? '';
              final mediaType = mediaData['type'] ?? 'image';
              final docId = mediaDocs[index].id;

              return ListTile(
                leading: Icon(mediaType == 'video' ? Icons.video_library : Icons.image),
                title: Text('${mediaType == 'video' ? 'Video' : 'Image'} ${index + 1}'),
                subtitle: Text('Tap to view'),
                onTap: () => _showMediaPreview(mediaUrl, mediaType),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteMedia(docId, mediaUrl),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Video Player Widget for video preview
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : Center(child: CircularProgressIndicator());
  }
}
