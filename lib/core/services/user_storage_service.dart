import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/login_response_model.dart';
import '../../features/navigation/presentation/cubit/bottom_navigation_cubit.dart';
import '../utils/role_utils.dart';
import 'shared_websocket_service.dart';

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
    try {
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
    } catch (e) {
      print('⚠️ Error saving user data: $e');
      // Re-throw the error so the calling code can handle it
      rethrow;
    }
  }

  // Get user data from SharedPreferences
  static Future<LoginResponseModel?> getUserData() async {
    try {
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
    } catch (e) {
      print('⚠️ Error getting user data from SharedPreferences: $e');
      return null;
    }
  }

  // Get auth token from SharedPreferences
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('⚠️ Error getting auth token: $e');
      return null;
    }
  }

  // Get user role from SharedPreferences
  static Future<UserRole?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString(_roleKey);

      if (roleString != null) {
        return UserRole.values.firstWhere(
          (role) => role.name == roleString,
          orElse: () => UserRole.picker,
        );
      }
      return null;
    } catch (e) {
      print('⚠️ Error getting user role: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('⚠️ Error checking login status: $e');
      return false;
    }
  }

  // Clear all user data (logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ All user data cleared from SharedPreferences');
    } catch (e) {
      print('⚠️ Error clearing user data: $e');
      // Continue with logout even if clearing fails
    }
  }

  // Centralized logout method that handles offline status update
  static Future<void> logout() async {
    try {
      // First, update user status to offline via WebSocket
      final userData = await getUserData();
      if (userData != null && userData.user != null) {
        final userId = userData.user!.id;
        final webSocketService = SharedWebSocketService();

        // Ensure WebSocket is connected before sending status update
        if (!webSocketService.isConnected) {
          await webSocketService.initialize();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Send offline status update
        final success = await webSocketService.sendStatusUpdate(
          userId,
          0,
        ); // 0 = offline
        if (success) {
          print('✅ Offline status sent via WebSocket for user $userId');
        } else {
          print(
            '⚠️ Failed to send offline status via WebSocket for user $userId',
          );
        }

        // Wait a moment for the status to be processed
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('⚠️ Error sending offline status during logout: $e');
      // Continue with logout even if status update fails
    }

    // Clear all user data
    await clearUserData();
    print('✅ Logout completed successfully');
  }

  // Save only user role
  static Future<void> saveUserRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, role.name);
    } catch (e) {
      print('⚠️ Error saving user role: $e');
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData['user'] != null) {
          userData['user']['availabilityStatus'] = status;
          await prefs.setString(_userKey, jsonEncode(userData));
        }
      }
    } catch (e) {
      print('⚠️ Error updating availability status: $e');
    }
  }

  // Get saved username
  static Future<String?> getSavedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('⚠️ Error getting saved username: $e');
      return null;
    }
  }

  // Check if SharedPreferences is available and working
  static Future<bool> isSharedPreferencesAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try to read a test value to ensure it's working
      await prefs.getKeys();
      return true;
    } catch (e) {
      print('⚠️ SharedPreferences is not available: $e');
      return false;
    }
  }

  // Get saved password
  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }
}
