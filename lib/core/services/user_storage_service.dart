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
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';

  // Save user data to SharedPreferences
  static Future<void> saveUserData(
    LoginResponseModel loginResponse,
    String username,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Save user data as JSON string
    await prefs.setString(_userKey, jsonEncode(loginResponse.toJson()));

    // Save auth token
    if (loginResponse.token != null) {
      await prefs.setString(_tokenKey, loginResponse.token!);
    }

    // Save username and password for auto-login
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);

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

    // Clear only user-specific keys (faster than clearing all)
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.setBool(_isLoggedInKey, false);

    // Also clear any other app-specific keys that might exist
    final keys = prefs.getKeys();
    final keysToRemove =
        keys
            .where(
              (key) =>
                  key.startsWith('user_') ||
                  key.startsWith('auth_') ||
                  key.startsWith('driver_') ||
                  key.startsWith('picker_') ||
                  key.startsWith('location_') ||
                  key.startsWith('notification_'),
            )
            .toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    print('✅ All user data cleared successfully');
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

  // Update user availability status in SharedPreferences
  static Future<void> updateAvailabilityStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      if (userData['user'] != null) {
        userData['user']['availabilityStatus'] = status;
        await prefs.setString(_userKey, jsonEncode(userData));
      }
    }
  }

  // Get saved username
  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Get saved password
  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }
}
