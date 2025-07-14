import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/login_response_model.dart';
import '../../features/navigation/presentation/cubit/bottom_navigation_cubit.dart';
import '../utils/role_utils.dart';

class UserStorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user data to SharedPreferences
  static Future<void> saveUserData(LoginResponseModel loginResponse) async {
    final prefs = await SharedPreferences.getInstance();

    // Save user data as JSON string
    await prefs.setString(_userKey, jsonEncode(loginResponse.toJson()));

    // Save auth token
    if (loginResponse.token != null) {
      await prefs.setString(_tokenKey, loginResponse.token!);
    }

    // Save user role
    final userRole = RoleUtils.getUserRoleFromApi(
      loginResponse.user?.role ?? 0,
      loginResponse.user?.driverType ?? '',
    );
    await prefs.setString(_roleKey, userRole.name);

    // Set logged in status
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get user data from SharedPreferences
  static Future<LoginResponseModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);

    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        return LoginResponseModel.fromJson(userData);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Get auth token from SharedPreferences
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user role from SharedPreferences
  static Future<UserRole?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_roleKey);

    if (roleString != null) {
      return UserRole.values.firstWhere(
        (role) => role.name == roleString,
        orElse: () => UserRole.picker,
      );
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear all user data (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Save only user role
  static Future<void> saveUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final userData = await getUserData();
    return userData?.user?.name;
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final userData = await getUserData();
    return userData?.user?.email;
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final userData = await getUserData();
    return userData?.user?.id;
  }
}
