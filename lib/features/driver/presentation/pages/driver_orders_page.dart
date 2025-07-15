import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:api_gateway/config/api_config.dart';

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage> {
  Timer? _timer;
  Position? _currentPosition;
  late WebSocketClient _wsClient;

  @override
  void initState() {
    super.initState();
    _wsClient = WebSocketClient();
    _wsClient.connect(ApiConfig.wsUrl);
    // _initForegroundTask();
  }

  void _initForegroundTask() async {
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
        eventAction: ForegroundTaskEventAction.repeat(1000),
        allowWakeLock: true,
      ),
    );
  }

  Future<void> _startForegroundTask() async {
    // LocationPermission permission = await Geolocator.requestPermission();
    // if (permission == LocationPermission.deniedForever ||
    //     permission == LocationPermission.denied) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text("Location permission denied")));
    //   return;
    // }

    // await FlutterForegroundTask.startService(
    //   notificationTitle: 'Location Tracking',
    //   notificationText: 'Tracking your location in the background',
    // );

    // _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
    //   Position position = await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.high,
    //   );
    //   // setState(() {
    //   //   _currentPosition = position;
    //   // });
    //   Fluttertoast.showToast(
    //     msg: 'Sending location: ${position.latitude}, ${position.longitude}',
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.red,
    //     textColor: Colors.white,
    //     fontSize: 16.0,
    //   );
    //   sendLocationToBackend(position.latitude, position.longitude);
    // });
    // WebSocketClient().connect(ApiConfig.wsUrl);
  }

  Future<void> sendLocationToBackend(double lat, double lng) async {
    print("Sending location: $lat, $lng");
    String token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MTgsImlhdCI6MTc1MjU3NzI2OCwiZXhwIjoxNzUyNjYzNjY4fQ.6G1tKA6pA_chbZAfH-_TGivj6-Ms7fP19PrKz7Ukz8s';
    // Simulated request (replace with your API)
    try {
      // await http.put(
      //   Uri.parse(
      //     'https://pickerdriver.testuatah.com/v1/api/qatar/pd_driverstatus.php',
      //   ),
      //   headers: {
      //     'Content-Type': 'application/json;charset=UTF-8',
      //     'Authorization': 'Bearer ${token}',
      //   },
      //   body: {'user_id': 18, 'lat': lat.toString(), 'long': lng.toString()},
      // );
      await ApiService(HttpClient(), WebSocketClient()).sendLocation(lat, lng);
    } catch (e) {
      print("Failed to send location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String locText =
        _currentPosition == null
            ? 'Not tracking yet'
            : 'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}';
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomAppBar(
              title: 'Location Tracking',
              trailing: ElevatedButton(
                onPressed: _startForegroundTask,
                child: Text('Start Tracking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
