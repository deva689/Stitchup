import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadStory(String userId) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('stories')
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('stories')
        .doc(userId)
        .collection('items')
        .add({
      'mediaUrl': downloadUrl,
      'mediaType': 'image',
      'timestamp': Timestamp.now(),
      'duration': 30,
    });
  }
}
