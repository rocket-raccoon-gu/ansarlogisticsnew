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
import 'core/services/permission_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/global_notification_service.dart';
import 'package:overlay_support/overlay_support.dart';
import 'core/services/user_storage_service.dart';
import 'core/services/shared_websocket_service.dart';
import 'core/services/barcode_scanner_service.dart';

// Firebase background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');

  // Show notification with sound even in background
  await NotificationService.showNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    payload: message.data.toString(),
  );
}

// Use GlobalNotificationService's navigator key
final GlobalKey<NavigatorState> navigatorKey =
    GlobalNotificationService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with timeout
    await FirebaseService.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print("⚠️ Firebase initialization timed out");
      },
    );

    // Initialize Notification Service with timeout
    await PermissionService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print("⚠️ Notification service initialization timed out");
      },
    );

    // Initialize WebSocket with timeout
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

        // Always show local notification with sound for foreground messages
        NotificationService.showNotification(
          title: message.notification?.title ?? 'New Notification',
          body: message.notification?.body ?? '',
          payload: message.data.toString(),
        );

        // If it's a new order, also show the in-app dialog
        if (message.data.containsKey('type') &&
            message.data['type'] == 'new_order') {
          final orderId = message.data['orderId'] ?? 'Unknown Order';
          final userRole = message.data['userRole'] ?? 'picker';
          GlobalNotificationService.showNewOrderNotification(
            orderId: orderId,
            userRole: userRole,
          );
        }
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print("✅ App initialization completed successfully");
  } catch (e) {
    print("❌ Error during app initialization: $e");
    // Continue with app launch even if initialization fails
  }

  runApp(OverlaySupport.global(child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('📱 App lifecycle state changed: $state');

    // Cancel any pending status update
    _statusUpdateTimer?.cancel();

    switch (state) {
      case AppLifecycleState.paused:
        // App is not visible but still running (e.g., notification center)
        print(
          '📱 App paused - User might still be active, not setting offline',
        );
        break;
      case AppLifecycleState.inactive:
        // App is transitioning (e.g., incoming call, system dialog)
        print(
          '📱 App inactive - User might still be active, not setting offline',
        );
        break;
      case AppLifecycleState.detached:
        // App is completely closed/terminated
        print('📱 App detached - Setting user offline');
        _setUserOfflineStatus();
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground
        print('📱 App resumed - Setting user online in 500ms');
        _statusUpdateTimer = Timer(const Duration(milliseconds: 500), () {
          _setUserOnlineStatus();
        });
        break;
      default:
        print('📱 App lifecycle: Unknown state - $state');
        break;
    }
  }

  Future<void> _setUserOfflineStatus() async {
    try {
      final userData = await UserStorageService.getUserData();
      if (userData != null && userData.user != null) {
        final userId = userData.user!.id;
        final webSocketService = SharedWebSocketService();

        // Send offline status update
        await webSocketService.sendStatusUpdate(userId, 0); // 0 = offline
        print('✅ App lifecycle: Offline status sent for user $userId');
      }
    } catch (e) {
      print('⚠️ App lifecycle: Error sending offline status: $e');
    }
  }

  Future<void> _setUserOnlineStatus() async {
    try {
      final userData = await UserStorageService.getUserData();
      if (userData != null && userData.user != null) {
        final userId = userData.user!.id;
        final webSocketService = SharedWebSocketService();

        // Ensure WebSocket is connected
        if (!webSocketService.isConnected) {
          await webSocketService.initialize();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Send online status update
        await webSocketService.sendStatusUpdate(userId, 1); // 1 = online
        print('✅ App lifecycle: Online status sent for user $userId');
      }
    } catch (e) {
      print('⚠️ App lifecycle: Error sending online status: $e');
    }
  }

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
