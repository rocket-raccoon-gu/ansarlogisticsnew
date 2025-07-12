import 'package:flutter/material.dart';
import 'presentation/pages/login_page.dart';

class AuthRoute {
  static const String login = '/login';
  static const String register = '/register';

  static getRoutes() {
    return {login: (context) => LoginPage()};
  }
}
