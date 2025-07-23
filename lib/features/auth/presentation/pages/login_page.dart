import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/login_form.dart';
import '../widgets/splash_screen.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/services/firebase_service.dart';
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
    // Request notification permissions
    await FirebaseService.requestNotificationPermissions();
    // Navigate to home
    if (mounted) {
      setState(() => _navigated = true); // <-- set flag
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
