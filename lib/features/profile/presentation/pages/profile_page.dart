import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shimmer/shimmer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../cubit/profile_cubit.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../core/services/driver_location_service.dart';
import '../../../../core/services/shared_websocket_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/global_notification_service.dart';
import 'package:overlay_support/overlay_support.dart';
import 'dart:async'; // Added for Timer

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..fetchUserData(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // const CustomAppBar(title: AppStrings.profile),
            const SizedBox(height: 10),
            const ProfileHeaderCard(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    const UserInfoCard(),
                    const SizedBox(height: 20),
                    const SettingsCard(),
                    const SizedBox(height: 20),
                    const AppVersionCard(),
                    const SizedBox(height: 20),
                    // const TestButtonsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _buildShimmerHeader();
        }

        if (state is ProfileLoaded) {
          final user = state.user;
          final isOnDuty = state.isOnline;

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[800]!],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.empId ?? 'ID: N/A',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isOnDuty
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnDuty ? Icons.work : Icons.coffee,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnDuty ? 'On Duty' : 'On Break',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Switch
                Column(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Switch(
                      value: isOnDuty,
                      onChanged: (val) {
                        context.read<ProfileCubit>().updateAvailabilityStatus(
                          val,
                        );
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green.withOpacity(0.8),
                      inactiveThumbColor: Colors.white.withOpacity(0.8),
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return _buildShimmerHeader();
      },
    );
  }

  Widget _buildShimmerHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            // Shimmer Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
            ),
            const SizedBox(width: 16),

            // Shimmer Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 24,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // Shimmer Switch
            Column(
              children: [
                Container(
                  height: 12,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 30,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _buildShimmerUserInfo();
        }

        if (state is ProfileLoaded) {
          final user = state.user;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow("Full Name", user.name ?? 'N/A', Icons.person),
                  _buildInfoRow(
                    "Employee ID",
                    user.empId ?? 'N/A',
                    Icons.badge,
                  ),
                  _buildInfoRow("Email", user.email ?? 'N/A', Icons.email),
                  _buildInfoRow(
                    "Mobile",
                    user.mobileNumber ?? 'N/A',
                    Icons.phone,
                  ),
                  if (user.vehicleNumber != null &&
                      user.vehicleNumber!.isNotEmpty)
                    _buildInfoRow(
                      "Vehicle",
                      user.vehicleNumber!,
                      Icons.directions_car,
                    ),
                ],
              ),
            ),
          );
        }

        return _buildShimmerUserInfo();
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerUserInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 18,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (int i = 0; i < 4; i++) ...[
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 16,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (i < 3) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key});

  // Clean up all services before logout (kept for compatibility)
  Future<void> _cleanupServices() async {
    // This method is now replaced by _simpleLogout()
    // Keeping it for compatibility but it's no longer used
    print('⚠️ _cleanupServices is deprecated, use _simpleLogout instead');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingTile(
              context,
              "Test Notification Sound",
              "Test notification with sound",
              Icons.notifications_active,
              Colors.blue,
              () => _testNotificationSound(context),
            ),
            const SizedBox(height: 20),
            _buildSettingTile(
              context,
              "Logout",
              "Sign out from your account",
              Icons.logout,
              Colors.red,
              () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _testNotificationSound(BuildContext context) async {
    try {
      print('🔔 Testing notification sound...');

      // Test local notification with sound using debug method
      await NotificationService.debugNotificationSound();

      // Also test global notification
      GlobalNotificationService.showCustomNotification(
        title: '🔔 Sound Test',
        message: 'Testing notification sound functionality',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🔔 Test notifications sent! Check if you hear the sound.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ Error testing notification sound: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error testing notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[600], size: 24),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? This will set your status to offline, clear all your data and stop location tracking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text('Logging out...'),
            ],
          ),
        );
      },
    );

    // Add a safety timeout to ensure dialog always closes
    Timer(const Duration(seconds: 3), () {
      if (context.mounted) {
        try {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        } catch (e) {
          print('⚠️ Safety timeout error: $e');
        }
      }
    });

    try {
      print('🔄 Starting logout process...');

      // Simple logout without complex timeout logic
      await _simpleLogout();

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate to login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('⚠️ Logout error: $e');

      // Always close dialog and navigate, regardless of errors
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate to login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _simpleLogout() async {
    try {
      // Clear user data immediately
      await UserStorageService.clearUserData();
      print('✅ User data cleared');

      // Clean up services with individual try-catch blocks
      try {
        final locationService = DriverLocationService();
        await locationService.stopTracking();
        print('✅ Location tracking stopped');
      } catch (e) {
        print('⚠️ Error stopping location tracking: $e');
      }

      try {
        final webSocketService = SharedWebSocketService();
        webSocketService.disconnect();
        print('✅ WebSocket disconnected');
      } catch (e) {
        print('⚠️ Error disconnecting WebSocket: $e');
      }

      try {
        await FlutterForegroundTask.stopService();
        print('✅ Foreground task stopped');
      } catch (e) {
        print('⚠️ Error stopping foreground task: $e');
      }

      print('✅ Logout completed successfully');
    } catch (e) {
      print('⚠️ Error during simple logout: $e');
      // Don't rethrow, just log the error
    }
  }
}

class TestButtonsCard extends StatelessWidget {
  const TestButtonsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Test Features",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              "Test Notification Sound",
              "Test local notification with sound",
              Icons.notifications_active,
              Colors.orange,
              () => _testNotificationSound(context),
            ),
            const SizedBox(height: 12),
            _buildTestButton(
              context,
              "Test Global Notification",
              "Test in-app notification dialog",
              Icons.notification_important,
              Colors.purple,
              () => _testGlobalNotification(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow, size: 20, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _testNotificationSound(BuildContext context) async {
    try {
      await NotificationService.testNotificationWithSound();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 Test notification sent! Check for sound.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test notification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testGlobalNotification(BuildContext context) {
    GlobalNotificationService.testNewOrderNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Global notification test triggered!'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

class AppVersionCard extends StatefulWidget {
  const AppVersionCard({super.key});

  @override
  State<AppVersionCard> createState() => _AppVersionCardState();
}

class _AppVersionCardState extends State<AppVersionCard> {
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '2.0.17';
        _buildNumber = '17';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 24,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ansar Logistics Picker App',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildVersionInfo(
                  'Version',
                  'v$_appVersion',
                  Icons.tag,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVersionInfo(
                  'Build',
                  '#$_buildNumber',
                  Icons.build,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Picker Application',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
