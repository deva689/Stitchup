import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _flutterLocalNotificationsInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// 🔐 Request permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    print('🔐 Notification permission: ${settings.authorizationStatus}');
  }

  /// 🧠 Top-level background tap handler
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    print('🔙 Background tap: ${response.payload}');
  }

  /// 🔄 Init everything
  Future<void> init() async {
    await _requestPermission();

    if (!_flutterLocalNotificationsInitialized) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iOSInit = DarwinInitializationSettings();

      final initSettings = InitializationSettings(
        android: androidInit,
        iOS: iOSInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📬 Notification tapped (foreground): ${response.payload}');
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      _flutterLocalNotificationsInitialized = true;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    FirebaseMessaging.onMessage.listen(showNotification);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📲 Notification opened app: ${message.notification?.title}');
    });

    final fcmToken = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $fcmToken');
  }

  /// 🔔 Show notification
  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification.title,
        notification.body,
        details,
      );
    } else {
      print('⚠️ No data in RemoteMessage');
    }
  }

  /// 💤 Background message handler
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    print('📩 BG Message: ${message.notification?.title}');
    print('📨 Data: ${message.data}');
  }
}
