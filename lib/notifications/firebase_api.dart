import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotificationService() async {
    // Request notification permission
    await _firebaseMessaging.requestPermission();

    // Get the token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('🔑 FCM Token: $fcmToken');

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(notification);
      }
    });

    // Handle messages when the app is opened from terminated state or background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // TODO: Handle tap on notification (navigate to chat maybe)
    });
  }

  void _showLocalNotification(RemoteNotification notification) {
    final androidDetails = AndroidNotificationDetails(
      'channelId',
      'StitchUp Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
    );
  }
}
