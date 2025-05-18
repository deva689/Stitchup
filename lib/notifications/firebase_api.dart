import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and local notifications
  Future<void> initNotificationService() async {
    // Request notification permissions
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else {
      debugPrint('❌ User declined or has not accepted notification permission');
    }

    // Get and save FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('🔑 FCM Token: $fcmToken');

    if (fcmToken != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
        });
      }
    }

    // Initialize local notifications with updated API
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidInitSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null) {
          debugPrint('🔔 Notification tapped with payload: $payload');
          // TODO: Navigate to chat screen with payload (e.g., chatId)
        }
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _showLocalNotification(notification, message.data);
      }
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      final chatId = data['chatId'];
      if (chatId != null) {
        debugPrint('📬 Open app from notification, chatId: $chatId');
        // TODO: Navigate to ChatScreen(chatId)
      }
    });
  }

  /// Show local notification when app is in foreground
  void _showLocalNotification(
      RemoteNotification notification, Map<String, dynamic> data) {
    const androidDetails = AndroidNotificationDetails(
      'stitchup_channel_id',
      'StitchUp Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      notificationDetails,
      payload: data['chatId'], // for navigation on tap
    );
  }
}
