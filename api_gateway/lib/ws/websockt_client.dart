import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
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
