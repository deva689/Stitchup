import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart'; // Import your UserModel

class AuthService {
  Future<void> saveUserData({
    required String name,
    required File? profileImage,
  }) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String phoneNumber = FirebaseAuth.instance.currentUser!.phoneNumber!;
    String profileUrl = '';

    if (profileImage != null) {
      final ref =
          FirebaseStorage.instance.ref().child('profilePics').child('$uid.jpg');
      await ref.putFile(profileImage);
      profileUrl = await ref.getDownloadURL();
    }

    UserModel user = UserModel(
      uid: uid,
      name: name,
      phoneNumber: phoneNumber,
      profilePic: profileUrl,
      about: 'Hey there! I am using StitchUp 😄',
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(user.toMap());
  }
}
