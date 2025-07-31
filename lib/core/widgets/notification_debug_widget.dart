import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class NotificationDebugWidget extends StatefulWidget {
  const NotificationDebugWidget({super.key});

  @override
  State<NotificationDebugWidget> createState() =>
      _NotificationDebugWidgetState();
}

class _NotificationDebugWidgetState extends State<NotificationDebugWidget> {
  Map<String, dynamic> _configStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await FirebaseService.checkNotificationConfiguration();
      setState(() {
        _configStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _configStatus = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Push Notification Debug',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else ...[
              // Configuration Status
              Text(
                'Configuration Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              _buildStatusItem(
                'FCM Token',
                _configStatus['fcm_token'] ?? false,
                _getFCMTokenDisplay(),
              ),

              _buildStatusItem(
                'Notification Permission',
                _configStatus['notification_permission'] ?? false,
                _configStatus['permission_status'] ?? 'Unknown',
              ),

              _buildStatusItem(
                'Firebase Initialized',
                _configStatus['firebase_initialized'] ?? false,
                'Firebase Core',
              ),

              _buildStatusItem(
                'Platform',
                true,
                _configStatus['platform'] ?? 'Unknown',
              ),

              SizedBox(height: 16),

              // Test Buttons
              Text(
                'Test Notifications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseService.comprehensiveNotificationTest();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Comprehensive test completed!'),
                          ),
                        );
                      },
                      icon: Icon(Icons.notifications),
                      label: Text('Comprehensive Test'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService.quickSoundTest();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Quick sound test sent!')),
                        );
                      },
                      icon: Icon(Icons.volume_up),
                      label: Text('Quick Sound Test'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _checkConfiguration();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Configuration refreshed!')),
                        );
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh Status'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFCMTokenDisplay() {
    final token = _configStatus['fcm_token_value'];
    if (token != null && token.toString().isNotEmpty) {
      final tokenStr = token.toString();
      return tokenStr.length > 20
          ? '${tokenStr.substring(0, 20)}...'
          : tokenStr;
    }
    return 'Not available';
  }

  Widget _buildStatusItem(String label, bool isSuccess, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14)),
                Text(
                  details,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
