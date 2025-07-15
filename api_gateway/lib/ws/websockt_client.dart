import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;

  void connect(String url1) {
    // _channel = WebSocketChannel.connect(Uri.parse(url));
    // _wsStatusSub = _channel!.stream.listen((status) {
    //   print('WebSocket status: $status');
    // });
    final url =
        'ws://qatar-api.testuatah.com/api/notification/?userId=1&role=admin';

    _channel = WebSocketChannel.connect(
      Uri.parse(
        'ws://qatar-api.testuatah.com/api/notification/?userId=1&role=admin',
      ),
    );

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
  }

  void disconnect() {
    _channel!.sink.close();
  }

  void send(String message) {
    _channel!.sink.add(message);
  }

  void onMessage(void Function(dynamic) onMessage) {
    _channel!.stream.listen(onMessage);
  }

  bool get isConnected => _channel != null;
}
