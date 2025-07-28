import 'package:flutter/material.dart';
import 'core/di/injector.dart';
import 'core/routes/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/widgets/in_app_notification.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:api_gateway/config/api_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/services/global_notification_service.dart';
import 'package:overlay_support/overlay_support.dart';

// Use GlobalNotificationService's navigator key
final GlobalKey<NavigatorState> navigatorKey =
    GlobalNotificationService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initialize();

  final ws = WebSocketClient();
  ws.connect(ApiConfig.wsUrl);
  getIt.registerSingleton<WebSocketClient>(ws);

  // Setup dependency injection
  setupDependencyInjection();

  // Configure Firebase messaging for foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Always show local notification with sound
      NotificationService.showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );

      // If it's a new order, also show the in-app dialog
      if (message.data.containsKey('type') &&
          message.data['type'] == 'new_order') {
        final orderId = message.data['order_id'] ?? 'Unknown Order';
        final userRole = message.data['user_role'] ?? 'picker';
        GlobalNotificationService.showNewOrderNotification(
          orderId: orderId,
          userRole: userRole,
        );
      }
    }
  });

  runApp(OverlaySupport.global(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ansar Logistics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
      builder: (context, child) => NetworkStatusListener(child: child!),
    );
  }
}

class NetworkStatusListener extends StatefulWidget {
  final Widget child;
  const NetworkStatusListener({required this.child, super.key});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _wasOffline;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChangedList,
    );
    _connectivity.checkConnectivity().then((result) {
      _onConnectivityChangedList(result);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onConnectivityChangedList(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (_wasOffline == null) {
      _wasOffline = isOffline;
      return;
    }
    if (isOffline && _wasOffline == false) {
      _showSnackBar('Your network is offline');
    } else if (!isOffline && _wasOffline == true) {
      _showSnackBar('You are back online');
    }
    _wasOffline = isOffline;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
