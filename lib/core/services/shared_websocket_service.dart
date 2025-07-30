import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';

class SharedWebSocketService {
  static final SharedWebSocketService _instance =
      SharedWebSocketService._internal();
  factory SharedWebSocketService() => _instance;
  SharedWebSocketService._internal();

  WebSocketClient? _wsClient;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentToken;
  List<void Function(dynamic)> _messageListeners = [];
  Timer? _pingTimer;
  Timer? _monitoringTimer;

  // Get the shared WebSocket client
  WebSocketClient get wsClient {
    if (_wsClient == null) {
      _wsClient = WebSocketClient();
    }
    return _wsClient!;
  }

  bool get isConnected => _isConnected && _wsClient?.isConnected == true;

  // Initialize WebSocket connection with token
  Future<bool> initialize() async {
    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        log("❌ No token available for WebSocket connection");
        return false;
      }

      // Only reconnect if token changed or not connected
      if (_currentToken != token || !isConnected) {
        await _connect(token).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            log("⚠️ WebSocket connection timed out");
            return false;
          },
        );
      }

      return isConnected;
    } catch (e) {
      log("❌ Error initializing WebSocket: $e");
      return false;
    }
  }

  // Connect to WebSocket with token
  Future<bool> _connect(String token) async {
    // Prevent multiple simultaneous connection attempts
    if (_isConnecting) {
      log("⚠️ WebSocket connection already in progress, skipping");
      return false;
    }

    try {
      _isConnecting = true;

      // Disconnect existing connection if any
      if (_wsClient != null) {
        _wsClient!.disconnect();
      }

      _wsClient = WebSocketClient();
      final wsUrl = 'wss://pickerdriver-api.testuatah.com/?token=$token';
      log("🌐 Connecting to shared WebSocket: $wsUrl");

      _wsClient!.connect(wsUrl);

      // Wait for connection to establish with timeout
      await Future.delayed(Duration(seconds: 3)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log("⚠️ WebSocket connection establishment timed out");
        },
      );

      _isConnected = _wsClient!.isConnected;
      _currentToken = token;

      if (_isConnected) {
        log("✅ Shared WebSocket connected successfully");

        // Set up message listener with connection monitoring
        _wsClient!.onMessage((message) {
          _handleMessage(message);
        });

        // Monitor connection status
        _startConnectionMonitoring();

        return true;
      } else {
        log("❌ Failed to establish WebSocket connection");
        return false;
      }
    } catch (e) {
      log("❌ Error connecting to WebSocket: $e");
      _isConnected = false;
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  // Monitor connection status and auto-reconnect
  void _startConnectionMonitoring() {
    // Cancel existing timer if any
    _monitoringTimer?.cancel();

    _monitoringTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (_wsClient != null && !_wsClient!.isConnected) {
        log("⚠️ WebSocket connection lost, attempting to reconnect...");
        _isConnected = false;

        // Attempt to reconnect
        final success = await _connect(_currentToken ?? '');
        if (!success) {
          log("❌ Auto-reconnection failed");
        } else {
          log("✅ Auto-reconnection successful");
        }
      }
    });

    // Start ping timer to keep connection alive
    _startPingTimer();
  }

  // Send periodic ping to keep connection alive
  void _startPingTimer() {
    // Cancel existing ping timer if any
    _pingTimer?.cancel();

    _pingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isConnected && _wsClient != null && _wsClient!.isConnected) {
        try {
          final pingMessage = {"route": "ping", "payload": {}};
          _wsClient!.send(jsonEncode(pingMessage));
          log("🏓 Ping sent to keep connection alive");
        } catch (e) {
          log("❌ Error sending ping: $e");
        }
      }
    });
  }

  // Handle incoming messages and notify all listeners
  void _handleMessage(dynamic message) {
    log("🔔 Shared WebSocket message: $message");
    for (final listener in _messageListeners) {
      try {
        listener(message);
      } catch (e) {
        log("❌ Error in message listener: $e");
      }
    }
  }

  // Add message listener
  void addMessageListener(void Function(dynamic) listener) {
    _messageListeners.add(listener);
  }

  // Remove message listener
  void removeMessageListener(void Function(dynamic) listener) {
    _messageListeners.remove(listener);
  }

  // Send message
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected) {
      log("❌ WebSocket not connected, attempting to reconnect...");
      final success = await initialize();
      if (!success) {
        log("❌ Failed to reconnect WebSocket");
        return false;
      }
    }

    try {
      final messageJson = jsonEncode(message);
      _wsClient!.send(messageJson);
      log("📤 Message sent via shared WebSocket: $messageJson");
      return true;
    } catch (e) {
      log("❌ Error sending message: $e");

      // If sending failed, try to reconnect and retry once
      if (_wsClient != null && !_wsClient!.isConnected) {
        log(
          "🔄 Connection lost during send, attempting to reconnect and retry...",
        );
        _isConnected = false;
        final success = await initialize();
        if (success) {
          try {
            final messageJson = jsonEncode(message);
            _wsClient!.send(messageJson);
            log(
              "📤 Message sent successfully after reconnection: $messageJson",
            );
            return true;
          } catch (retryError) {
            log("❌ Failed to send message after reconnection: $retryError");
            return false;
          }
        }
      }

      return false;
    }
  }

  // Send location update
  Future<bool> sendLocationUpdate(
    int userId,
    double latitude,
    double longitude,
  ) async {
    final message = {
      "route": "locationUpdate",
      "payload": {"id": userId, "latitude": latitude, "longitude": longitude},
    };
    return await sendMessage(message);
  }

  // Send status update
  Future<bool> sendStatusUpdate(int userId, int status) async {
    final message = {
      "route": "updateLoginStatus",
      "payload": {"id": userId, "status": status},
    };
    return await sendMessage(message);
  }

  // Send getUser request
  Future<bool> sendGetUserRequest(int userId) async {
    final message = {
      "route": "getUser",
      "payload": {"id": userId},
    };
    return await sendMessage(message);
  }

  // Disconnect
  void disconnect() {
    // Cancel timers
    _pingTimer?.cancel();
    _monitoringTimer?.cancel();
    _pingTimer = null;
    _monitoringTimer = null;

    if (_wsClient != null) {
      _wsClient!.disconnect();
      _wsClient = null;
    }
    _isConnected = false;
    _currentToken = null;
    _messageListeners.clear();
    log("🔌 Shared WebSocket disconnected");
  }
}
