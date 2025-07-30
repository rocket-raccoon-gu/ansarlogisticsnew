import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:developer';

class PermissionService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Permission status tracking
  static bool _notificationPermissionGranted = false;
  static bool _locationPermissionGranted = false;
  static bool _cameraPermissionGranted = false;

  // Getters for permission status
  static bool get notificationPermissionGranted =>
      _notificationPermissionGranted;
  static bool get locationPermissionGranted => _locationPermissionGranted;
  static bool get cameraPermissionGranted => _cameraPermissionGranted;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    log("🔐 Initializing PermissionService...");

    // Initialize local notifications
    await _initializeLocalNotifications();
    _isInitialized = true;

    log("✅ PermissionService initialized");
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
      log('🔔 Creating Android notification channel with sound...');

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
        log('✅ Android notification channel created successfully with sound');
      } catch (e) {
        log('❌ Error creating Android notification channel: $e');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      log('🔔 iOS notification sound will use alert.mp3');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    log('Local notification tapped: ${response.payload}');
  }

  // Request all permissions together
  static Future<Map<String, bool>> requestAllPermissions() async {
    log("🔐 Requesting all permissions...");

    Map<String, bool> results = {};

    try {
      // Request notification permissions
      log("📱 Requesting notification permissions...");
      await _requestNotificationPermissions();
      results['notification'] = _notificationPermissionGranted;

      // Request location permissions
      log("📍 Requesting location permissions...");
      await _requestLocationPermissions();
      results['location'] = _locationPermissionGranted;

      // Request camera permissions
      log("📷 Requesting camera permissions...");
      await _requestCameraPermissions();
      results['camera'] = _cameraPermissionGranted;

      log("✅ All permissions requested. Results: $results");
    } catch (e) {
      log("❌ Error requesting permissions: $e");
    }

    return results;
  }

  // Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    try {
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

      _notificationPermissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      log('📱 Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      log('❌ Error requesting notification permissions: $e');
      _notificationPermissionGranted = false;
    }
  }

  // Request location permissions
  static Future<void> _requestLocationPermissions() async {
    try {
      // Request fine location permission
      PermissionStatus fineLocationStatus = await Permission.location.request();

      // Request background location permission (for drivers)
      PermissionStatus backgroundLocationStatus =
          await Permission.locationWhenInUse.request();

      _locationPermissionGranted =
          fineLocationStatus.isGranted || backgroundLocationStatus.isGranted;
      log(
        '📍 Location permission - Fine: ${fineLocationStatus.isGranted}, Background: ${backgroundLocationStatus.isGranted}',
      );
    } catch (e) {
      log('❌ Error requesting location permissions: $e');
      _locationPermissionGranted = false;
    }
  }

  // Request camera permissions
  static Future<void> _requestCameraPermissions() async {
    try {
      PermissionStatus cameraStatus = await Permission.camera.request();
      _cameraPermissionGranted = cameraStatus.isGranted;
      log('📷 Camera permission: ${cameraStatus.isGranted}');
    } catch (e) {
      log('❌ Error requesting camera permissions: $e');
      _cameraPermissionGranted = false;
    }
  }

  // Check current permission status
  static Future<Map<String, bool>> checkCurrentPermissions() async {
    Map<String, bool> status = {};

    try {
      // Check notification permission
      NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      status['notification'] =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      // Check location permission
      PermissionStatus locationStatus = await Permission.location.status;
      status['location'] = locationStatus.isGranted;

      // Check camera permission
      PermissionStatus cameraStatus = await Permission.camera.status;
      status['camera'] = cameraStatus.isGranted;

      // Update internal status
      _notificationPermissionGranted = status['notification'] ?? false;
      _locationPermissionGranted = status['location'] ?? false;
      _cameraPermissionGranted = status['camera'] ?? false;

      log("🔍 Current permission status: $status");
    } catch (e) {
      log("❌ Error checking permissions: $e");
    }

    return status;
  }

  // Open app settings if permissions are denied
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      log("🔧 Opened app settings");
    } catch (e) {
      log("❌ Error opening app settings: $e");
    }
  }

  // Legacy method for backward compatibility
  static Future<void> requestPermissions() async {
    await requestAllPermissions();
  }
}
