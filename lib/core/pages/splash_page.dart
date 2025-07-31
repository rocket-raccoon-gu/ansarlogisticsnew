import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../services/user_storage_service.dart';
import '../routes/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/data/models/login_request_model.dart';
import '../../features/auth/domain/usecases/login_cases.dart';
import '../../core/di/injector.dart';
import '../services/firebase_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    if (_navigated) return;

    final isLoggedIn = await UserStorageService.isLoggedIn();

    if (isLoggedIn) {
      // Try to get saved credentials for auto-login
      final savedUsername = await UserStorageService.getSavedUsername();
      final savedPassword = await UserStorageService.getSavedPassword();

      if (savedUsername != null && savedPassword != null) {
        // Attempt auto-login with saved credentials
        final deviceToken = await FirebaseService.getFCMToken();
        await _performAutoLogin(
          savedUsername,
          savedPassword,
          deviceToken ?? '',
        );
      } else {
        // No saved credentials, go to login
        if (!_navigated) {
          _navigated = true;
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } else {
      // User is not logged in, navigate to login
      if (!_navigated) {
        _navigated = true;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  Future<void> _performAutoLogin(
    String email,
    String password,
    String deviceToken,
  ) async {
    try {
      // Create auth cubit for auto-login
      final authCubit = AuthCubit(loginCases: getIt<LoginCases>());

      // Listen to auth state changes
      authCubit.stream.listen((state) {
        if (_navigated) return;
        if (state is AuthSuccess) {
          _navigated = true;
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else if (state is AuthFailure) {
          _navigated = true;
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });

      // Perform login with saved credentials
      final loginRequest = LoginRequestModel(
        username: email,
        password: password,
        device_token: deviceToken,
        version: '2.0.17',
      );

      await authCubit.login(loginRequest);
    } catch (e) {
      if (!_navigated) {
        _navigated = true;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
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
