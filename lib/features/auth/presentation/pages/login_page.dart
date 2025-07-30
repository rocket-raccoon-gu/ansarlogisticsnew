import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer';
import '../cubit/auth_cubit.dart';
import '../widgets/login_form.dart';
import '../widgets/splash_screen.dart';
import '../widgets/permission_request_dialog.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/constants/app_assets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showSplash = true;
  bool _navigated = false; // <-- add this

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  Future<void> _handleLoginSuccess() async {
    try {
      // Show permission request dialog after successful login
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => PermissionRequestDialog(
                onPermissionsGranted: () {
                  if (mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    _navigateToHome();
                  }
                },
                onPermissionsDenied: () {
                  if (mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    _navigateToHome();
                  }
                },
              ),
        );
      }
    } catch (e) {
      log("❌ Error in login success handling: $e");
      // Reset navigation flag and show error
      if (mounted) {
        setState(() => _navigated = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToHome() async {
    try {
      if (mounted) {
        setState(() => _navigated = true);

        // Add a small delay to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        // Navigate with timeout
        await Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            log("⚠️ Navigation timed out, forcing navigation");
            // Force navigation if timeout occurs
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          },
        );
      }
    } catch (e) {
      log("❌ Error navigating to home: $e");
      if (mounted) {
        setState(() => _navigated = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onSplashComplete: _onSplashComplete);
    }

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: AppBar(elevation: 0, backgroundColor: Colors.white),
        ),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: BlocProvider(
          create: (context) => getIt<AuthCubit>(),
          child: BlocConsumer<AuthCubit, AuthState>(
            builder: (context, state) {
              if (_navigated) {
                // Show a loading indicator while navigating
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AuthLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 250,
                        child: Image.asset(
                          AppAssets.logo,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: 250,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  "Logo",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      const SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(),
                      ),
                    ],
                  ),
                );
              }
              return const LoginForm();
            },
            listener: (context, state) async {
              if (state is AuthSuccess) {
                setState(() => _navigated = true); // <-- set flag here as well
                await _handleLoginSuccess();
              } else if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
