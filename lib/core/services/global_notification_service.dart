import 'package:flutter/material.dart';
import '../widgets/global_notification_dialog.dart';
import '../utils/role_utils.dart';

class GlobalNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showNewOrderNotification({
    required String orderId,
    required String userRole,
    VoidCallback? onOkPressed,
  }) {
    if (navigatorKey.currentContext == null) return;

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder:
          (context) => GlobalNotificationDialog(
            title: 'New Order Assigned',
            message: 'You got assigned a new order: $orderId',
            orderId: orderId,
            userRole: userRole,
            onOkPressed: () {
              Navigator.of(context).pop(); // Close dialog
              onOkPressed?.call(); // Call custom callback if provided
              _refreshOrderPage(userRole); // Auto-refresh order page
            },
          ),
    );
  }

  static void showCustomNotification({
    required String title,
    required String message,
    String? orderId,
    String? userRole,
    VoidCallback? onOkPressed,
  }) {
    if (navigatorKey.currentContext == null) return;

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder:
          (context) => GlobalNotificationDialog(
            title: title,
            message: message,
            orderId: orderId,
            userRole: userRole,
            onOkPressed: () {
              Navigator.of(context).pop(); // Close dialog
              onOkPressed?.call(); // Call custom callback if provided
              if (orderId != null && userRole != null) {
                _refreshOrderPage(userRole); // Auto-refresh order page
              }
            },
          ),
    );
  }

  static void _refreshOrderPage(String userRole) {
    // Navigate to the appropriate order page based on role
    switch (userRole.toLowerCase()) {
      case 'picker':
        _navigateToPickerOrders();
        break;
      case 'driver':
        _navigateToDriverOrders();
        break;
      default:
        print('Unknown user role: $userRole');
    }
  }

  static void _navigateToPickerOrders() {
    if (navigatorKey.currentContext == null) return;

    // Navigate to picker orders page and trigger refresh
    Navigator.of(
      navigatorKey.currentContext!,
    ).pushNamedAndRemoveUntil('/picker-orders', (route) => false);
  }

  static void _navigateToDriverOrders() {
    if (navigatorKey.currentContext == null) return;

    // Navigate to driver orders page and trigger refresh
    Navigator.of(
      navigatorKey.currentContext!,
    ).pushNamedAndRemoveUntil('/driver-orders', (route) => false);
  }

  // Test method to show notification from anywhere
  static void testNewOrderNotification() {
    showNewOrderNotification(orderId: 'NOL-000093177', userRole: 'picker');
  }
}
