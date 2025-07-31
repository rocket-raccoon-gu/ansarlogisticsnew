import 'package:flutter/material.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/firebase_service.dart';
import 'dart:developer';

class PermissionRequestDialog extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const PermissionRequestDialog({
    super.key,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
  });

  @override
  State<PermissionRequestDialog> createState() =>
      _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _isRequesting = false;
  Map<String, bool> _permissionResults = {};
  bool _showSettingsButton = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final currentPermissions =
        await PermissionService.checkCurrentPermissions();
    setState(() {
      _permissionResults = currentPermissions;
    });
  }

  Future<void> _requestAllPermissions() async {
    if (!mounted) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final results = await PermissionService.requestAllPermissions();

      if (!mounted) return;

      setState(() {
        _permissionResults = results;
        _isRequesting = false;
        _showSettingsButton = results.values.contains(false);
      });

      // Check if all permissions are granted
      if (results.values.every((granted) => granted)) {
        log("✅ All permissions granted");

        // Get and send FCM token after permissions are granted
        await _getAndSendFCMToken();

        if (mounted) {
          widget.onPermissionsGranted?.call();
        }
      } else {
        log("⚠️ Some permissions denied: $results");
        if (mounted) {
          setState(() {
            _showSettingsButton = true;
          });
        }
      }
    } catch (e) {
      log("❌ Error requesting permissions: $e");
      if (mounted) {
        setState(() {
          _isRequesting = false;
          _showSettingsButton = true;
        });
      }
    }
  }

  Future<void> _getAndSendFCMToken() async {
    try {
      log("📱 Getting FCM token after permissions granted...");
      final token = await FirebaseService.getFCMToken();
      if (token != null) {
        log("✅ FCM token obtained: $token");
        // The token will be automatically sent to server in getFCMToken method
      } else {
        log("❌ Failed to get FCM token");
      }
    } catch (e) {
      log("❌ Error getting FCM token: $e");
    }
  }

  Future<void> _openAppSettings() async {
    await PermissionService.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: Colors.blue),
          SizedBox(width: 8),
          Text('App Permissions'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To provide you with the best experience, we need the following permissions:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),

          // Notification Permission
          _buildPermissionItem(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Receive order updates and important alerts',
            isGranted: _permissionResults['notification'] ?? false,
          ),

          SizedBox(height: 12),

          // Location Permission
          _buildPermissionItem(
            icon: Icons.location_on,
            title: 'Location',
            description:
                'Track delivery location and provide accurate services',
            isGranted: _permissionResults['location'] ?? false,
          ),

          SizedBox(height: 12),

          // Camera Permission
          _buildPermissionItem(
            icon: Icons.camera_alt,
            title: 'Camera',
            description: 'Scan barcodes for quick order processing',
            isGranted: _permissionResults['camera'] ?? false,
          ),

          if (_showSettingsButton) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some permissions were denied. You can enable them in app settings.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_showSettingsButton)
          TextButton(onPressed: _openAppSettings, child: Text('Open Settings')),
        TextButton(
          onPressed: () {
            widget.onPermissionsDenied?.call();
          },
          child: Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isRequesting ? null : _requestAllPermissions,
          child:
              _isRequesting
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text('Grant Permissions'),
        ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Row(
      children: [
        Icon(icon, color: isGranted ? Colors.green : Colors.grey, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isGranted ? Colors.green : Colors.black,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (isGranted)
                    Icon(Icons.check_circle, color: Colors.green, size: 16)
                  else
                    Icon(Icons.cancel, color: Colors.grey, size: 16),
                ],
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
