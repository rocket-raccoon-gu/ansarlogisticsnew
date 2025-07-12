import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (context) => LoginPage());
      default:
        return MaterialPageRoute(builder: (context) => const Scaffold());
    }
  }
}
