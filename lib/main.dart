import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/main/stitchupsplash.dart'; // Make sure you have this:
import 'package:stitchup/notifications/firebase_api.dart'; // if you have one
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebasePerformance performance = FirebasePerformance.instance;

  Trace myTrace = FirebasePerformance.instance.newTrace("test_trace");
  await myTrace.start();
// Code you want to measure
  await myTrace.stop();

  // ✅ Register App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    webProvider: ReCaptchaV3Provider('your-site-key'), // only for web
  );

  // ✅ Ask contact permission
  await askContactPermission();

  // ✅ FCM setup if FirebaseApi exists
  await FirebaseApi().initNotificationService(); // Make sure this class exists

  runApp(const MyApp());
}

// 🔒 Ask Contact Permission Function
Future<void> askContactPermission() async {
  var status = await Permission.contacts.status;
  if (!status.isGranted) {
    await Permission.contacts.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stitchupsplash(); // Assuming this returns a MaterialApp
  }
}
