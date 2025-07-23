import 'dart:async';
import 'dart:developer';

import 'package:ansarlogisticsnew/features/driver/presentation/cubit/driver_orders_page_cubit.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:api_gateway/config/api_config.dart';
import 'dart:convert';
import '../../../../core/services/driver_location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/driver_order_list_item.dart';
import 'driver_order_details_page.dart';
import 'driver_route_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';

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
    _wsClient = getIt<WebSocketClient>();

    _initForegroundTask();
  }

  final _statusController =
      StreamController<LocationTrackingStatus>.broadcast();
  LocationTrackingStatus _status = LocationTrackingStatus.idle;
  Stream<LocationTrackingStatus> get statusStream => _statusController.stream;
  LocationTrackingStatus get status => _status;
  void setStatus(LocationTrackingStatus status) {
    _status = status;
    _statusController.add(status);
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
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location permission denied")));
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Location Tracking',
      notificationText: 'Tracking your location in the background',
    );

    setStatus(LocationTrackingStatus.loading);

    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setStatus(LocationTrackingStatus.tracking);
      // setState(() {
      //   _currentPosition = position;
      // });
      Fluttertoast.showToast(
        msg: 'Sending location: ${position.latitude}, ${position.longitude}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      _wsClient.send(
        jsonEncode({
          'user_id': 18,
          'lat': position.latitude.toString(),
          'long': position.longitude.toString(),
        }),
      );
      sendLocationToBackend(position.latitude, position.longitude);
    });
  }

  Future<void> sendLocationToBackend(double lat, double lng) async {
    print("Sending location: $lat, $lng");
    String token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MTgsImlhdCI6MTc1MjY0MzkzMywiZXhwIjoxNzUyNzMwMzMzfQ.F3vbuFocVeMWzyvbDz6QbB_vt3kc4LoaFzlswg15yE8';
    // Simulated request (replace with your API)
    try {
      final user = await UserStorageService.getUserData();
      final response = await http.put(
        Uri.parse(
          'https://pickerdriver.testuatah.com/v1/api/qatar/pd_driverstatus.php',
        ),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': 'Bearer ${token}',
        },
        body: jsonEncode({
          'user_id': user?.user?.id,
          'lat': lat.toString(),
          'long': lng.toString(),
        }),
      );
      if (response.statusCode == 200) {
        log("Location sent successfully");
      } else {
        log("Failed to send location: ${response.statusCode}");
      }
      await ApiService(HttpClient(), WebSocketClient()).sendLocation(lat, lng);
    } catch (e) {
      print("Failed to send location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String locText;
    if (_currentPosition == null) {
      locText = 'Not tracking yet';
    } else {
      locText =
          'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}';
    }
    return Scaffold(
      body: Column(
        children: [
          FutureBuilder<String?>(
            future: UserStorageService.getUserName(),
            builder: (context, snapshot) {
              final username = snapshot.data ?? '';
              return CustomAppBar(
                title: 'Hi, $username',
                trailing: StreamBuilder<LocationTrackingStatus>(
                  stream: statusStream,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? LocationTrackingStatus.idle;
                    return ElevatedButton(
                      onPressed:
                          status == LocationTrackingStatus.tracking
                              ? null
                              : status == LocationTrackingStatus.loading
                              ? () {
                                Fluttertoast.showToast(
                                  msg: 'Your location is being fetched',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.orange,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              }
                              : _startForegroundTask,
                      child: Text('Start Tracking'),
                    );
                  },
                ),
              );
            },
          ),
          // Move BlocProvider up to wrap both the button and the list
          Expanded(
            child: BlocProvider(
              create: (context) => getIt<DriverOrdersPageCubit>(),
              child: BlocBuilder<DriverOrdersPageCubit, DriverOrdersPageState>(
                builder: (context, state) {
                  if (state is DriverOrdersPageLoaded) {
                    final orders = state.orders;
                    return Column(
                      children: [
                        if (orders.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.route),
                                label: const Text('View My Route'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async {
                                  // Get current location
                                  Position? position;
                                  try {
                                    position =
                                        await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high,
                                        );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not get current location.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (position == null) return;
                                  final cubit = getIt<DriverOrdersPageCubit>();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DriverRoutePage(
                                            orders: cubit.orders,
                                            driverLocation: LatLng(
                                              position!.latitude,
                                              position.longitude,
                                            ),
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (orders.isEmpty)
                          const Expanded(
                            child: Center(child: Text('No orders available.')),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return DriverOrderListItem(
                                  order: order,
                                  onDirectionTap:
                                      order.customerZone != null
                                          ? () => _openMaps(order.customerZone)
                                          : null,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => DriverOrderDetailsPage(
                                              order: order,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
