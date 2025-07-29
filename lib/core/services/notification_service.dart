import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Don't request notification permissions during initialization
    // Permissions will be requested after successful login
    print(
      'NotificationService initialized - permissions will be requested after login',
    );

    // Initialize local notifications
    await _initializeLocalNotifications();
    _isInitialized = true;
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      print('🔔 Creating Android notification channel with sound...');

      AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ansar_logistics_channel',
        'Ansar Logistics Notifications',
        description: 'Channel for Ansar Logistics push notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      );

      try {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
        print('✅ Android notification channel created successfully with sound');
      } catch (e) {
        print('❌ Error creating Android notification channel: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      print('🔔 iOS notification sound will use alert.mp3');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
    // You can navigate to specific screens based on payload
  }

  static Future<void> requestPermissions() async {
    // Request permissions for iOS
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      print('🔔 Showing notification with sound: $title - $body');

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'ansar_logistics_channel',
            'Ansar Logistics Notifications',
            channelDescription:
                'Channel for Ansar Logistics push notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
            // Force sound to play even in foreground
            fullScreenIntent: false,
            category: AndroidNotificationCategory.message,
            visibility: NotificationVisibility.public,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'alert.mp3',
            // Force sound to play even in foreground
            interruptionLevel: InterruptionLevel.active,
          );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      print(
        '✅ Local notification shown successfully with sound: $title - $body',
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  static void _onNotificationTap(String? payload) {
    print('Notification tapped: $payload');
    // Handle notification tap
    // You can navigate to specific screens based on payload
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('All notifications cancelled');
  }

  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    print('Notification $id cancelled');
  }

  // Test notification with sound
  static Future<void> testNotificationWithSound() async {
    print('🔔 Testing notification sound...');
    await showNotification(
      title: '🔔 Sound Test',
      body: 'This notification should play the alert sound!',
      payload: 'sound_test',
    );
  }

  // Test notification for debugging
  static Future<void> debugNotificationSound() async {
    print('🔔 Debug: Testing notification sound configuration...');

    try {
      // Test with different notification IDs to ensure they all play sound
      await showNotification(
        title: '🔔 Test 1',
        body: 'First test notification with sound',
        payload: 'test1',
        id: 1001,
      );

      await Future.delayed(const Duration(seconds: 2));

      await showNotification(
        title: '🔔 Test 2',
        body: 'Second test notification with sound',
        payload: 'test2',
        id: 1002,
      );

      print('✅ Debug: Both test notifications sent successfully');
    } catch (e) {
      print('❌ Debug: Error testing notification sound: $e');
    }
  }
}
