import 'dart:developer';
import 'dart:convert';
import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  List<void Function(dynamic)> _messageListeners = [];

  void connect(String url1) {
    log("🌐 Connecting to WebSocket: $url1");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url1));

      log("✅ WebSocket connected");

      // Set up the main stream listener
      _subscription = _channel!.stream.listen(
        (message) {
          log('🔔 New WebSocket Message: $message');
          // Notify all registered listeners
          for (final listener in _messageListeners) {
            listener(message);
          }
        },
        onDone: () {
          log('❌ WebSocket connection closed');
          _subscription = null;
        },
        onError: (error) {
          log('⚠️ WebSocket error: $error');
          _subscription = null;
        },
      );
    } catch (e) {
      log("🚨 WebSocket failed to connect: $e");
    }
  }

  void disconnect() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _messageListeners.clear();
  }

  void send(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    } else {
      log('❌ WebSocket not connected - cannot send message');
    }
  }

  void sendLocationUpdate(int userId, double latitude, double longitude) {
    if (_channel != null) {
      final locationMessage = {
        "route": "locationUpdate",
        "payload": {"id": userId, "latitude": latitude, "longitude": longitude},
      };
      _channel!.sink.add(jsonEncode(locationMessage));
      log('📍 Location update sent: ${jsonEncode(locationMessage)}');
    } else {
      log('❌ WebSocket not connected - cannot send location update');
    }
  }

  void onMessage(void Function(dynamic) onMessage) {
    _messageListeners.add(onMessage);
  }

  void removeMessageListener(void Function(dynamic) onMessage) {
    _messageListeners.remove(onMessage);
  }

  bool get isConnected => _channel != null && _subscription != null;
}
