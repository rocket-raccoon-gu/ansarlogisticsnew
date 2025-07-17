import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;

  void connect(String url1) {
    log("🌐 Connecting to WebSocket: $url1");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url1));

      log("✅ WebSocket connected");

      _channel!.stream.listen(
        (message) {
          log('🔔 New WebSocket Message: $message');
        },
        onDone: () {
          log('❌ WebSocket connection closed');
        },
        onError: (error) {
          log('⚠️ WebSocket error: $error');
        },
      );
    } catch (e) {
      log("🚨 WebSocket failed to connect: $e");
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
    }
  }

  void send(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    } else {
      // Optionally: throw or log an error
    }
  }

  void onMessage(void Function(dynamic) onMessage) {
    _channel!.stream.listen(onMessage);
  }

  bool get isConnected => _channel != null;
}
