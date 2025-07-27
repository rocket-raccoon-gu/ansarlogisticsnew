import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'package:ansarlogisticsnew/core/services/shared_websocket_service.dart';
import 'package:ansarlogisticsnew/core/di/injector.dart';

enum LocationTrackingStatus { idle, loading, tracking }

class DriverLocationService {
  static final DriverLocationService _instance =
      DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  Timer? _timer;
  Position? _currentPosition;
  late SharedWebSocketService _sharedWebSocket;
  static const String _trackingPreferenceKey =
      'driver_location_tracking_enabled';

  final _statusController =
      StreamController<LocationTrackingStatus>.broadcast();
  LocationTrackingStatus _status = LocationTrackingStatus.idle;

  Stream<LocationTrackingStatus> get statusStream => _statusController.stream;
  LocationTrackingStatus get status => _status;

  void setStatus(LocationTrackingStatus status) {
    _status = status;
    _statusController.add(status);
  }

  // Initialize the service
  Future<void> initialize() async {
    _sharedWebSocket = getIt<SharedWebSocketService>();
    await _sharedWebSocket.initialize();
    await _initForegroundTask();
    await _checkAndAutoStartTracking();
  }

  // Check if tracking was previously enabled and auto-start if needed
  Future<void> _checkAndAutoStartTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final trackingEnabled = prefs.getBool(_trackingPreferenceKey) ?? false;

    if (trackingEnabled) {
      // Auto-start tracking if it was previously enabled
      await _startForegroundTask();
    }
  }

  // Save tracking preference
  Future<void> _saveTrackingPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingPreferenceKey, enabled);
  }

  // Stop tracking and clear preference
  Future<void> stopTracking() async {
    _timer?.cancel();
    setStatus(LocationTrackingStatus.idle);
    await _saveTrackingPreference(false);

    Fluttertoast.showToast(
      msg: 'Location tracking stopped',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_channel_id',
        channelName: 'Location Tracking',
        channelDescription: 'Tracks location in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          60000,
        ), // 60 seconds = 1 minute
        allowWakeLock: true,
      ),
    );
  }

  Future<void> startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      log("Location permission denied");
      return;
    }

    // Ensure WebSocket is connected before starting tracking
    if (!_sharedWebSocket.isConnected) {
      log("Connecting to WebSocket before starting tracking...");
      await _sharedWebSocket.initialize();
      // Wait for connection to establish
      await Future.delayed(Duration(seconds: 3));
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Location Tracking',
      notificationText: 'Tracking your location in the background',
    );

    setStatus(LocationTrackingStatus.loading);

    // Send first location immediately
    Position firstPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setStatus(LocationTrackingStatus.tracking);

    Fluttertoast.showToast(
      msg:
          'First location sent: ${firstPosition.latitude}, ${firstPosition.longitude}',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Send first location immediately
    log("🚀 Sending first location immediately");
    final user = await UserStorageService.getUserData();
    await _sharedWebSocket.sendLocationUpdate(
      user?.user?.id ?? 18,
      firstPosition.latitude,
      firstPosition.longitude,
    );
    log(
      "✅ First location sent: ${firstPosition.latitude}, ${firstPosition.longitude}",
    );

    // Save tracking preference as enabled
    await _saveTrackingPreference(true);

    // Then start timer for subsequent locations every minute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      log("🕐 Timer triggered - sending location update (every 1 minute)");

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setStatus(LocationTrackingStatus.tracking);

      // Fluttertoast.showToast(
      //   msg: 'Sending location: ${position.latitude}, ${position.longitude}',
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   timeInSecForIosWeb: 1,
      //   backgroundColor: Colors.blue,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );

      // Send location update via WebSocket with proper format
      final user = await UserStorageService.getUserData();
      await _sharedWebSocket.sendLocationUpdate(
        user?.user?.id ?? 18,
        position.latitude,
        position.longitude,
      );

      log(
        "✅ Location sent via timer: ${position.latitude}, ${position.longitude}",
      );
    });
  }

  Future<void> _startForegroundTask() async {
    await startTracking();
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }

  // Check WebSocket connection status
  bool get isWebSocketConnected => _sharedWebSocket.isConnected;

  // Force reconnect WebSocket
  Future<void> reconnectWebSocket() async {
    log("Force reconnecting WebSocket...");
    _sharedWebSocket.disconnect();
    await Future.delayed(Duration(seconds: 1));
    await _sharedWebSocket.initialize();
    await Future.delayed(Duration(seconds: 2));
    log(
      "WebSocket reconnection attempt completed. Connected: ${_sharedWebSocket.isConnected}",
    );
  }
}
