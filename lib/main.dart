import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/main/stitchupsplash.dart';
import 'package:stitchup/notifications/firebase_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Firebase
    await Firebase.initializeApp();

    // ✅ Sign in anonymously if not already signed in
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // ✅ Request contact permission
    await askContactPermission();

    // ✅ Initialize notifications
    await FirebaseApi().initNotificationService();
  } catch (e) {
    debugPrint('Firebase Init/Auth Error: $e');
  }

  // ✅ Run app
  runApp(const MyApp());
}

// 🔒 Ask contact permission
Future<void> askContactPermission() async {
  var status = await Permission.contacts.status;
  if (!status.isGranted) {
    await Permission.contacts.request();
  }
}

void saveFCMTokenToUser() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'fcmToken': fcmToken,
  });

  // Background handler
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('⏰ Background message: ${message.notification?.title}');
  }
}

// ✅ Root Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stitchupsplash(),
    );
  }
}
