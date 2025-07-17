import 'package:flutter/material.dart';
import 'core/di/injector.dart';
import 'core/routes/app_router.dart';
import 'core/services/firebase_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:api_gateway/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initialize();

  final ws = WebSocketClient();
  ws.connect(ApiConfig.wsUrl);
  getIt.registerSingleton<WebSocketClient>(ws);

  // Setup dependency injection
  setupDependencyInjection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
