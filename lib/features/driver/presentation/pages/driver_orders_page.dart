import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import 'package:http/http.dart' as http;

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage> {
  Timer? _timer;
  Position? _currentPosition;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  void _initForegroundTask() {
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
        interval: 5000, // 5 seconds
        allowWakeLock: true,
        allowWifiLock: true,
        autoRunOnBoot: false,
      ),
    );
  }

  Future<void> _startForegroundTask() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Location Tracking',
      notificationText: 'Tracking your location in the background',
    );

    setState(() {
      _isTracking = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      sendLocationToBackend(position.latitude, position.longitude);
    });
  }

  Future<void> sendLocationToBackend(double lat, double lng) async {
    // Replace with your actual API endpoint and driver ID
    print("Sending location: $lat, $lng");
    try {
      await http.post(
        Uri.parse('https://your-backend.example.com/location'),
        body: {
          'driver_id': '12345',
          'latitude': lat.toString(),
          'longitude': lng.toString(),
        },
      );
    } catch (e) {
      print("Failed to send location: $e");
    }
  }

  Future<void> _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
    _timer?.cancel();
    setState(() {
      _currentPosition = null;
      _isTracking = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopForegroundTask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String locText =
        _currentPosition == null
            ? 'Not tracking yet'
            : 'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(locText),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isTracking ? null : _startForegroundTask,
              child: const Text('Start Tracking'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isTracking ? _stopForegroundTask : null,
              child: const Text('Stop Tracking'),
            ),
            const SizedBox(height: 40),
            const Icon(Icons.local_shipping, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Driver Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your driver orders will appear here',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
