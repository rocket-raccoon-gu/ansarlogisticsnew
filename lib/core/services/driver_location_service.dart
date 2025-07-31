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
  SharedWebSocketService? _sharedWebSocket;
  static const String _trackingPreferenceKey =
      'driver_location_tracking_enabled';
  bool _isInitialized = false;

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
    // Prevent multiple initializations
    if (_isInitialized) {
      log("⚠️ DriverLocationService already initialized, skipping");
      return;
    }

    try {
      log("🚀 Initializing DriverLocationService...");

      _sharedWebSocket = getIt<SharedWebSocketService>();

      // Initialize WebSocket with timeout
      await _sharedWebSocket?.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          log(
            "⚠️ WebSocket initialization timed out, continuing without WebSocket",
          );
          return false;
        },
      );

      // Initialize foreground task with timeout
      await _initForegroundTask().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log("⚠️ Foreground task initialization timed out");
          throw TimeoutException('Foreground task initialization timed out');
        },
      );

      // Check and auto-start tracking with timeout
      await _checkAndAutoStartTracking().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log("⚠️ Auto-start tracking check timed out");
        },
      );

      _isInitialized = true;
      log("✅ DriverLocationService initialized successfully");
    } catch (e) {
      log("❌ Error initializing DriverLocationService: $e");
      // Don't rethrow - allow the app to continue without location tracking
      // The UI will handle this gracefully
    }
  }

  // Check if tracking was previously enabled and auto-start if needed
  Future<void> _checkAndAutoStartTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final trackingEnabled = prefs.getBool(_trackingPreferenceKey) ?? false;

    if (trackingEnabled) {
      // Auto-start tracking if it was previously enabled
      log("🔄 Auto-starting location tracking (was previously enabled)");
      setStatus(LocationTrackingStatus.loading);
      await _startForegroundTask();
    } else {
      log("ℹ️ Location tracking was not previously enabled");
      setStatus(LocationTrackingStatus.idle);
    }
  }

  // Refresh the current status based on actual tracking state
  Future<void> refreshStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final trackingEnabled = prefs.getBool(_trackingPreferenceKey) ?? false;

    if (trackingEnabled && _timer != null) {
      // If tracking is enabled and timer is active, we're tracking
      setStatus(LocationTrackingStatus.tracking);
    } else if (trackingEnabled && _timer == null) {
      // If tracking is enabled but timer is not active, we're loading
      setStatus(LocationTrackingStatus.loading);
    } else {
      // If tracking is not enabled, we're idle
      setStatus(LocationTrackingStatus.idle);
    }
  }

  // Restore tracking state from preferences
  Future<void> restoreTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final trackingEnabled = prefs.getBool(_trackingPreferenceKey) ?? false;

    if (trackingEnabled) {
      log("🔄 Restoring tracking state - was previously enabled");
      setStatus(LocationTrackingStatus.loading);
      // Don't auto-start here, let the user decide
    } else {
      log("ℹ️ Restoring tracking state - was not previously enabled");
      setStatus(LocationTrackingStatus.idle);
    }
  }

  // Get current tracking status from preferences
  Future<bool> isTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trackingPreferenceKey) ?? false;
  }

  // Save tracking preference
  Future<void> _saveTrackingPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingPreferenceKey, enabled);
    log("💾 Saved tracking preference: $enabled");
  }

  // Stop tracking and clear preference
  Future<void> stopTracking() async {
    log("🛑 Stopping location tracking...");
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
    if (_sharedWebSocket != null && !_sharedWebSocket!.isConnected) {
      log("Connecting to WebSocket before starting tracking...");
      await _sharedWebSocket!.initialize();
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
    if (_sharedWebSocket != null) {
      await _sharedWebSocket!.sendLocationUpdate(
        user?.user?.id ?? 18,
        firstPosition.latitude,
        firstPosition.longitude,
      );
    }
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
      if (_sharedWebSocket != null) {
        await _sharedWebSocket!.sendLocationUpdate(
          user?.user?.id ?? 18,
          position.latitude,
          position.longitude,
        );
      }

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
  bool get isWebSocketConnected => _sharedWebSocket?.isConnected ?? false;

  // Force reconnect WebSocket
  Future<void> reconnectWebSocket() async {
    log("Force reconnecting WebSocket...");
    if (_sharedWebSocket != null) {
      _sharedWebSocket!.disconnect();
      await Future.delayed(Duration(seconds: 1));
      await _sharedWebSocket!.initialize();
      await Future.delayed(Duration(seconds: 2));
      log(
        "WebSocket reconnection attempt completed. Connected: ${_sharedWebSocket!.isConnected}",
      );
    }
  }
}
