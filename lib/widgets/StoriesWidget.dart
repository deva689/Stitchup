import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:stitchup/widgets/story_editor_screen.dart';

class StoriesWidget extends StatefulWidget {
  final String currentUserId;

  const StoriesWidget({super.key, required this.currentUserId});

  @override
  State<StoriesWidget> createState() => _StoriesWidgetState();
}

class _StoriesWidgetState extends State<StoriesWidget> {
  List<Map<String, dynamic>> contactsWithStories = [];

  @override
  void initState() {
    super.initState();
    fetchContactsStories();
  }

  Future<void> fetchContactsStories() async {
    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: widget.currentUserId)
        .get();

    final otherUsers = chatSnapshot.docs.map((doc) {
      final participants = List<String>.from(doc['participants']);
      return participants.firstWhere((id) => id != widget.currentUserId);
    }).toSet();

    List<Map<String, dynamic>> userStories = [];

    for (String userId in otherUsers) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final storySnapshot = await FirebaseFirestore.instance
          .collection('stories')
          .doc(userId)
          .collection('items')
          .get();

      if (storySnapshot.docs.isNotEmpty) {
        userStories.add({
          'userId': userId,
          'username': userDoc['username'],
          'photoUrl': userDoc['photoUrl'],
        });
      }
    }

    setState(() {
      contactsWithStories = userStories;
    });
  }

  Future<void> _pickMediaAndOpenEditor(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    final pickedFile = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);

    if (pickedFile != null) {
      final picked = File(pickedFile.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryEditorScreen(
            file: picked,
            image: picked,
            isVideo: isVideo,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    }
  }

  void _showMediaPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pick Image'),
              onTap: () {
                Navigator.of(context).pop();
                _pickMediaAndOpenEditor(ImageSource.gallery, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Pick Video'),
              onTap: () {
                Navigator.of(context).pop();
                _pickMediaAndOpenEditor(ImageSource.gallery, true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryViewer(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Placeholder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: contactsWithStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showMediaPickerSheet,
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text("Add Story", style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          final storyUser = contactsWithStories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _openStoryViewer(storyUser['userId']),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(storyUser['photoUrl']),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  storyUser['username'],
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
