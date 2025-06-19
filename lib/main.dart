import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/splash.dart/stitchupsplash.dart';
import 'package:stitchup/notifications/firebase_api.dart';

// 🔹 Background FCM message handler (must be top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('⏰ Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Firebase
    await Firebase.initializeApp();

    // ✅ Set up FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ Sign in anonymously if needed
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // ✅ Request Contacts permission
    await _askContactPermission();

    // ✅ Activate App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );

    // ✅ Save FCM token
    await _saveFCMToken();

    // ✅ Initialize local notification service
    await FirebaseApi().initNotificationService();
  } catch (e, st) {
    debugPrint('❌ Firebase init/auth error: $e');
    debugPrint('$st');
  }

  runApp(const MyApp());
}

Future<void> _askContactPermission() async {
  final status = await Permission.contacts.status;
  if (!status.isGranted) {
    await Permission.contacts.request();
  }
}

Future<void> _saveFCMToken() async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': fcmToken,
        });
      }
    } else {
      debugPrint('❌ Failed to get FCM token');
    }
  } catch (e) {
    debugPrint('❌ Error saving FCM token: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StitchupSplash(),
    );
  }
}
