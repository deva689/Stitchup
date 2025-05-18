import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> uploadStory() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) return;

  final file = File(pickedFile.path);
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final userId = currentUser.uid;

  // 🔍 Fetch user data (assuming it's in 'users' collection)
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

  final userData = userDoc.data();
  if (userData == null) return;

  final username = userData['name'] ?? '';
  final profileUrl = sanitizeUrl(userData['profileUrl']);

  // 📤 Upload media to Firebase Storage
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('stories')
      .child(userId)
      .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

  await storageRef.putFile(file);
  final mediaUrl = await storageRef.getDownloadURL();

  final timestamp = Timestamp.now();

  // 📝 Prepare story data
  final storyData = {
    'uid': userId,
    'username': username,
    'profileUrl': profileUrl,
    'mediaUrl': mediaUrl,
    'mediaType': 'image',
    'timestamp': timestamp,
    'duration': 30, // in seconds
  };

  // 🗃️ Save to user's story subcollection
  final storiesRef =
      FirebaseFirestore.instance.collection('stories').doc(userId);

  await storiesRef.set({
    'uid': userId,
    'username': username,
    'profileUrl': profileUrl,
    'lastUpdated': timestamp,
  }, SetOptions(merge: true));

  await storiesRef.collection('items').add(storyData);
}

String sanitizeUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (!url.startsWith('http')) return '';
  return url;
}
