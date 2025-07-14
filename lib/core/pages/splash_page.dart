import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../services/user_storage_service.dart';
import '../routes/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await UserStorageService.isLoggedIn();

    if (isLoggedIn) {
      // User is logged in, navigate to home
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      // User is not logged in, navigate to login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(AppAssets.logo, width: 150, height: 150),
            const SizedBox(height: 30),

            // Subtitle
            const Text(
              'Logistics Management System',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),

            // Loading indicator
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: Colors.grey[300],
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
