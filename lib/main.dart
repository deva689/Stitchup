import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/splash.dart/stitchupsplash.dart';
import 'package:stitchup/notifications/firebase_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Background message handler - MUST be top level
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('⏰ Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Supabase
  await Supabase.initialize(
    url: 'https://wndamcfaujomvmyfusjq.supabase.co', // Replace with real URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InduZGFtY2ZhdWpvbXZteWZ1c2pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2NTE1MjEsImV4cCI6MjA2NTIyNzUyMX0.020gmWUxSU35VgQQ2QZ_2BInUl9YwH4144UKfPHF0Pk',
  );

  try {
    // ✅ Firebase
    await Firebase.initializeApp();

    // ✅ Background FCM handler registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ Anonymous auth
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // ✅ Permissions
    await askContactPermission();

    // ✅ FCM Token Save
    await saveFCMTokenToUser();

    // ✅ Local notification setup
    await FirebaseApi().initNotificationService();
  } catch (e, st) {
    debugPrint('❌ Firebase Init/Auth Error: $e');
    debugPrint('$st');
  }

  runApp(const MyApp());
}

Future<void> askContactPermission() async {
  var status = await Permission.contacts.status;
  if (!status.isGranted) {
    await Permission.contacts.request();
  }
}

Future<void> saveFCMTokenToUser() async {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final fcmToken = await FirebaseMessaging.instance.getToken();

  if (fcmToken != null) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': fcmToken,
    });
  } else {
    print("FCM token is null. Check Firebase Messaging setup.");
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
