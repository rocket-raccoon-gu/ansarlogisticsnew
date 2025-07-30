import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Added for Color

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

      // Create multiple notification channels for different scenarios
      List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'ansar_logistics_channel',
          'Ansar Logistics Notifications',
          description: 'Channel for Ansar Logistics push notifications',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
        ),
        // Fallback channel with default system sound
        AndroidNotificationChannel(
          'ansar_logistics_fallback',
          'Ansar Logistics Fallback',
          description: 'Fallback channel with system sound',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        ),
        // High priority channel for critical notifications
        AndroidNotificationChannel(
          'ansar_logistics_critical',
          'Ansar Logistics Critical',
          description: 'Critical notifications with maximum priority',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 0, 0),
        ),
      ];

      try {
        final androidPlugin =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidPlugin != null) {
          for (var channel in channels) {
            await androidPlugin.createNotificationChannel(channel);
            print('✅ Android notification channel created: ${channel.id}');
          }
        }
        print('✅ All Android notification channels created successfully');
      } catch (e) {
        print('❌ Error creating Android notification channels: $e');
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
    String channelId = 'ansar_logistics_channel',
  }) async {
    try {
      print('🔔 Showing notification with sound: $title - $body');
      print('🔔 Using channel: $channelId');

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            channelId,
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
            // Additional settings for release builds
            channelShowBadge: true,
            enableLights: true,
            ledColor: const Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
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

      // Fallback: try with different channel
      if (channelId != 'ansar_logistics_fallback') {
        print('🔄 Trying fallback channel...');
        await showNotification(
          title: title,
          body: body,
          payload: payload,
          id: id,
          channelId: 'ansar_logistics_fallback',
        );
      }
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

  // Comprehensive sound test for release builds
  static Future<void> testAllNotificationChannels() async {
    print('🔔 Testing all notification channels for sound...');

    try {
      // Test main channel
      print('🔔 Testing main channel...');
      await showNotification(
        title: '🔔 Main Channel Test',
        body: 'Testing main notification channel',
        payload: 'main_channel_test',
        id: 2001,
        channelId: 'ansar_logistics_channel',
      );

      await Future.delayed(const Duration(seconds: 3));

      // Test fallback channel
      print('🔔 Testing fallback channel...');
      await showNotification(
        title: '🔔 Fallback Channel Test',
        body: 'Testing fallback notification channel',
        payload: 'fallback_channel_test',
        id: 2002,
        channelId: 'ansar_logistics_fallback',
      );

      await Future.delayed(const Duration(seconds: 3));

      // Test critical channel
      print('🔔 Testing critical channel...');
      await showNotification(
        title: '🔔 Critical Channel Test',
        body: 'Testing critical notification channel',
        payload: 'critical_channel_test',
        id: 2003,
        channelId: 'ansar_logistics_critical',
      );

      print('✅ Debug: All notification channels tested successfully');
    } catch (e) {
      print('❌ Debug: Error testing notification channels: $e');
    }
  }

  // Check device notification settings
  static Future<void> checkNotificationSettings() async {
    print('🔔 Checking notification settings...');

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidPlugin != null) {
          // Check if channels exist
          final channels = await androidPlugin.getNotificationChannels();
          if (channels != null) {
            print('🔔 Found ${channels.length} notification channels:');
            for (var channel in channels) {
              print(
                '  - ${channel.id}: ${channel.name} (Importance: ${channel.importance})',
              );
            }
          } else {
            print('🔔 No notification channels found');
          }
        }
      }
    } catch (e) {
      print('❌ Error checking notification settings: $e');
    }
  }

  // Verify sound file accessibility
  static Future<void> verifySoundFile() async {
    print('🔔 Verifying sound file accessibility...');

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Try to show a test notification with the sound file
        await showNotification(
          title: '🔔 Sound File Test',
          body: 'Testing if alert.mp3 is accessible',
          payload: 'sound_file_test',
          id: 3001,
        );
        print('✅ Sound file test notification sent');
      }
    } catch (e) {
      print('❌ Error verifying sound file: $e');
    }
  }

  // Comprehensive notification sound debugging
  static Future<void> debugNotificationSoundComplete() async {
    print('🔔 Starting comprehensive notification sound debugging...');

    // Check notification settings
    await checkNotificationSettings();

    await Future.delayed(const Duration(seconds: 1));

    // Verify sound file
    await verifySoundFile();

    await Future.delayed(const Duration(seconds: 1));

    // Test all channels
    await testAllNotificationChannels();

    print('🔔 Comprehensive notification sound debugging completed');
  }

  // Aggressive sound testing for release builds
  static Future<void> aggressiveSoundTest() async {
    print('🔔 Starting aggressive sound testing...');

    try {
      // Test 1: Basic notification with system sound
      print('🔔 Test 1: Basic notification with system sound');
      await _localNotifications.show(
        4001,
        '🔔 System Sound Test',
        'Testing with system default sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'system_sound_test',
            'System Sound Test',
            channelDescription: 'Testing system sound',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      // Test 2: Notification with custom sound (no channel)
      print('🔔 Test 2: Notification with custom sound (no channel)');
      await _localNotifications.show(
        4002,
        '🔔 Custom Sound Test',
        'Testing with custom alert.mp3 sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'custom_sound_test',
            'Custom Sound Test',
            channelDescription: 'Testing custom sound',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      // Test 3: Notification with different sound file
      print('🔔 Test 3: Notification with notification.mp3 sound');
      await _localNotifications.show(
        4003,
        '🔔 Alternative Sound Test',
        'Testing with notification.mp3 sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alternative_sound_test',
            'Alternative Sound Test',
            channelDescription: 'Testing alternative sound',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 0, 255, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      // Test 4: Notification without sound (vibration only)
      print('🔔 Test 4: Notification without sound (vibration only)');
      await _localNotifications.show(
        4004,
        '🔔 Vibration Only Test',
        'Testing vibration without sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'vibration_only_test',
            'Vibration Only Test',
            channelDescription: 'Testing vibration only',
            importance: Importance.high,
            priority: Priority.high,
            playSound: false,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 2000, 1000, 2000]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 0, 0, 255),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      print('✅ Aggressive sound testing completed');
    } catch (e) {
      print('❌ Error during aggressive sound testing: $e');
    }
  }

  // Device-specific debugging
  static Future<void> debugDeviceSettings() async {
    print('🔔 Debugging device-specific settings...');

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidPlugin != null) {
          // Check if channels exist
          final channels = await androidPlugin.getNotificationChannels();
          if (channels != null) {
            print('🔔 Found ${channels.length} notification channels:');
            for (var channel in channels) {
              print('  - ${channel.id}: ${channel.name}');
              print('    Importance: ${channel.importance}');
              print('    Sound: ${channel.sound}');
              print('    Play Sound: ${channel.playSound}');
              print('    Vibration: ${channel.enableVibration}');
              print('    Lights: ${channel.enableLights}');
            }
          }

          // Check if we can create a new channel
          try {
            await androidPlugin.createNotificationChannel(
              AndroidNotificationChannel(
                'debug_test_channel',
                'Debug Test Channel',
                description: 'Channel for debugging',
                importance: Importance.max,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('alert'),
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
              ),
            );
            print('✅ Debug test channel created successfully');
          } catch (e) {
            print('❌ Error creating debug test channel: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error debugging device settings: $e');
    }
  }

  // Test notification with maximum priority
  static Future<void> testMaximumPriorityNotification() async {
    print('🔔 Testing maximum priority notification...');

    try {
      await _localNotifications.show(
        5001,
        '🔔 MAXIMUM PRIORITY',
        'This notification should break through all restrictions!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'maximum_priority',
            'Maximum Priority',
            channelDescription: 'Maximum priority notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([
              0,
              2000,
              1000,
              2000,
              1000,
              2000,
            ]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 2000,
            ledOffMs: 1000,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            channelShowBadge: true,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );
      print('✅ Maximum priority notification sent');
    } catch (e) {
      print('❌ Error sending maximum priority notification: $e');
    }
  }

  // Simple test method that can be called from anywhere
  static Future<void> quickSoundTest() async {
    print('🔔 Quick sound test...');

    try {
      // Test with the most basic configuration
      await _localNotifications.show(
        9999,
        '🔔 SOUND TEST',
        'If you hear this, sound is working!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'quick_test',
            'Quick Test',
            channelDescription: 'Quick sound test',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          ),
        ),
      );
      print('✅ Quick sound test notification sent');
    } catch (e) {
      print('❌ Error in quick sound test: $e');
    }
  }

  // Check if device is in Do Not Disturb mode
  static Future<void> checkDoNotDisturbMode() async {
    print('🔔 Checking Do Not Disturb mode...');

    try {
      // Try to send a notification that should break through DND
      await _localNotifications.show(
        8888,
        '🔔 DND TEST',
        'This should break through Do Not Disturb!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'dnd_test',
            'DND Test',
            channelDescription: 'Testing Do Not Disturb bypass',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 2000, 1000, 2000]),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
      );
      print('✅ DND test notification sent');
    } catch (e) {
      print('❌ Error in DND test: $e');
    }
  }

  // Comprehensive test for all notification scenarios
  static Future<void> comprehensiveNotificationTest() async {
    print('🔔 Starting comprehensive notification test...');
    print('📱 This will test notifications in different app states');

    try {
      // Test 1: Local notification (app running/background)
      print('🔔 Test 1: Local notification (app running/background)');
      await _localNotifications.show(
        6001,
        '🔔 LOCAL NOTIFICATION',
        'This is a local notification with custom sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'comprehensive_test_local',
            'Comprehensive Test - Local',
            channelDescription: 'Testing local notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      // Test 2: FCM-style notification (simulates push notification)
      print('🔔 Test 2: FCM-style notification (simulates push notification)');
      await _localNotifications.show(
        6002,
        '🔔 PUSH NOTIFICATION',
        'This simulates a push notification with custom sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ansar_logistics_channel', // Use the same channel as FCM
            'Ansar Logistics Notifications',
            channelDescription:
                'Channel for Ansar Logistics push notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      // Test 3: Critical notification (should break through all restrictions)
      print(
        '🔔 Test 3: Critical notification (should break through all restrictions)',
      );
      await _localNotifications.show(
        6003,
        '🔔 CRITICAL NOTIFICATION',
        'This is a critical notification that should break through all restrictions!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'comprehensive_test_critical',
            'Comprehensive Test - Critical',
            channelDescription: 'Testing critical notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([
              0,
              2000,
              1000,
              2000,
              1000,
              2000,
            ]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 2000,
            ledOffMs: 1000,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            channelShowBadge: true,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

      print('✅ Comprehensive notification test completed');
      print('📱 Check your device for 3 notifications with sound');
      print('🎵 All notifications should play alert.mp3 sound');
      print('📳 All notifications should have vibration');
      print('💡 All notifications should have red LED light');
    } catch (e) {
      print('❌ Error during comprehensive notification test: $e');
    }
  }

  // Test notification that simulates real FCM push notification
  static Future<void> testFCMStyleNotification() async {
    print('🔔 Testing FCM-style notification...');
    print('📱 This simulates how notifications work when app is terminated');

    try {
      await _localNotifications.show(
        7001,
        '🔔 FCM STYLE TEST',
        'This simulates a real FCM push notification with custom sound',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ansar_logistics_channel', // Same channel as MainActivity.kt
            'Ansar Logistics Notifications',
            channelDescription:
                'Channel for Ansar Logistics push notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alert'),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
        ),
      );

      print('✅ FCM-style notification sent');
      print('🎵 This should play alert.mp3 sound');
      print('📱 This simulates how notifications work when app is terminated');
    } catch (e) {
      print('❌ Error in FCM-style notification test: $e');
    }
  }
}
