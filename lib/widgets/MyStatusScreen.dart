import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/status_model.dart';
import '../widgets/StoryViewerScreen.dart';

class MyStatusScreen extends StatefulWidget {
  final String userId;

  const MyStatusScreen({super.key, required this.userId});

  @override
  State<MyStatusScreen> createState() => _MyStatusScreenState();
}

class _MyStatusScreenState extends State<MyStatusScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    deleteExpiredStatuses();
  }

  Future<void> deleteExpiredStatuses() async {
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('status')
        .where('userId', isEqualTo: widget.userId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final mediaUrl = data['mediaUrl'];

      if (now.difference(timestamp).inHours >= 24) {
        await FirebaseFirestore.instance
            .collection('status')
            .doc(doc.id)
            .delete();
        try {
          final ref = FirebaseStorage.instance.refFromURL(mediaUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Failed to delete media: $e');
        }
      }
    }
  }

  Future<void> uploadStatus(File file, bool isVideo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String statusId = const Uuid().v4();
    String path = 'status/${widget.userId}/$statusId';
    final ref = FirebaseStorage.instance.ref().child(path);

    UploadTask uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    StatusModel newStatus = StatusModel(
      userId: widget.userId,
      statusId: statusId,
      mediaUrl: downloadUrl,
      isVideo: isVideo,
      timestamp: DateTime.now(),
      views: [],
    );

    await FirebaseFirestore.instance
        .collection('status')
        .doc(statusId)
        .set(newStatus.toJson());
  }

  Future<void> pickMedia(bool isVideo) async {
    final picked = await (isVideo
        ? _picker.pickVideo(source: ImageSource.gallery)
        : _picker.pickImage(source: ImageSource.gallery));

    if (picked != null) {
      File file = File(picked.path);
      await uploadStatus(file, isVideo);
    }
  }

  Future<void> saveToDevice(String url, String fileName) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    final response = await http.get(Uri.parse(url));
    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved to device")),
    );
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat.yMMMd().format(date);
  }

  void showStatusOptions(StatusModel status, String docId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Forward'),
            onTap: () {
              Navigator.pop(context);
              // Implement your forwarding logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Forward clicked')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Save'),
            onTap: () async {
              Navigator.pop(context);
              final extension = status.isVideo ? 'mp4' : 'jpg';
              await saveToDevice(
                  status.mediaUrl, 'status_${status.statusId}.$extension');
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () async {
              Navigator.pop(context);
              Share.share(status.mediaUrl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('status')
                  .doc(docId)
                  .delete();
              try {
                final ref =
                    FirebaseStorage.instance.refFromURL(status.mediaUrl);
                await ref.delete();
              } catch (e) {
                debugPrint('Storage deletion error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Status'),
        leading: const BackButton(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('status')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No status yet.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = StatusModel.fromJson(data);
              final docId = docs[index].id;

              return ListTile(
                leading: CircleAvatar(
                    backgroundImage: NetworkImage(status.mediaUrl)),
                title: Text('${status.views.length} views'),
                subtitle: Text(timeAgo(status.timestamp)),
                onTap: () async {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(status.userId)
                      .get();
                  final userName = userDoc.data()?['name'] ?? 'Unknown';
                  final profileImage = userDoc.data()?['profileUrl'] ?? '';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatusViewScreen(
                        userName: userName,
                        profileImage: profileImage,
                        statusList: [
                          {
                            'url': status.mediaUrl,
                            'isVideo': status.isVideo,
                            'timestamp': status.timestamp,
                          }
                        ],
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => showStatusOptions(status, docId),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // Optional: Add text status
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.green,
            child: const Icon(Icons.camera_alt),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text('Upload Image'),
                      onTap: () async {
                        Navigator.pop(context);
                        await pickMedia(false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam),
                      title: const Text('Upload Video'),
                      onTap: () async {
                        Navigator.pop(context);
                        await pickMedia(true);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
