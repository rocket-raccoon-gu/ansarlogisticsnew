import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Notification Test',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.testNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test notification sent!')),
              );
            },
            child: const Text('Send Test Notification'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              String? token = await FirebaseService.getFCMToken();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('FCM Token: ${token ?? 'Not available'}'),
                ),
              );
            },
            child: const Text('Get FCM Token'),
          ),
        ],
      ),
    );
  }
}
