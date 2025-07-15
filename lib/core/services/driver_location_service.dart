import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';

class DriverLocationService {
  static final DriverLocationService _instance =
      DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  final WebSocketClient _wsClient = WebSocketClient();
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  DateTime? _lastSentTime;

  Future<void> startTracking() async {
    if (_isTracking) return;
    _isTracking = true;

    // Request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      // Handle permission denied
      _isTracking = false;
      return;
    }

    // TODO: Start foreground service for Android using flutter_foreground_task

    // Connect to WebSocket using your client
    // _wsClient.connect(
    //   'wss://your-api-server/ws',
    // ); // TODO: Replace with your actual URL

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    ).listen((Position position) {
      final now = DateTime.now();
      if (_lastSentTime == null ||
          now.difference(_lastSentTime!).inSeconds >= 4) {
        final data = '{"lat":${position.latitude},"lng":${position.longitude}}';
        log(data);
        // _wsClient.send(data);
        // _lastSentTime = now;
      }
    });
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionStream?.cancel();
    _positionStream = null;
    _wsClient.disconnect();
    _lastSentTime = null;
    // TODO: Stop foreground service for Android
  }

  bool get isTracking => _isTracking;
}

class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[LocationTask] onStart at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    () async {
      print('[LocationTask] onRepeatEvent at $timestamp');
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print(
          '[LocationTask] position: lat=${pos.latitude}, lng=${pos.longitude}',
        );
        await ApiService(
          HttpClient(),
          WebSocketClient(),
        ).sendLocation(pos.latitude, pos.longitude);
      } catch (e) {
        print('[LocationTask] error fetching/sending location: $e');
      }
    }();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isForceStop) async {
    print('[LocationTask] onDestroy at $timestamp');
  }

  @override
  void onNotificationPressed() {
    print('[LocationTask] notification pressed');
  }

  @override
  void onButtonPressed(String id) {
    print('[LocationTask] button pressed: $id');
  }
}
