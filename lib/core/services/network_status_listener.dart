import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Network Status Listener
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
