import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../core/services/shared_websocket_service.dart';
import '../../../../core/di/injector.dart';
import 'dart:convert';
import 'dart:developer';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  late SharedWebSocketService _sharedWebSocket;

  ProfileCubit() : super(ProfileLoading()) {
    _sharedWebSocket = getIt<SharedWebSocketService>();
  }

  Future<void> fetchUserData() async {
    emit(ProfileLoading());
    try {
      final userData = await UserStorageService.getUserData();
      if (userData != null && userData.user != null) {
        final isOnline = userData.user!.availabilityStatus == "1";
        emit(ProfileLoaded(user: userData.user!, isOnline: isOnline));
        // Initialize shared WebSocket after loading user data
        await _sharedWebSocket.initialize();
        // Add message listener
        _sharedWebSocket.addMessageListener(_handleWebSocketMessage);

        // Fetch current status from server to ensure UI reflects actual status
        await _refreshUserProfile();
      } else {
        emit(ProfileError('No user data found.'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load user data.'));
    }
  }

  // Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      log("🔔 Received WebSocket message: $message");

      if (message is String) {
        final data = jsonDecode(message);

        // Handle status update response
        if (data['route'] == 'updateLoginStatus') {
          final status = data['payload']['status'];
          final userId = data['payload']['id'];

          log("📊 Status update received - User: $userId, Status: $status");

          // Update the UI based on the response
          _updateUserStatus(status == 1);
        }

        // Handle getUser response
        if (data['route'] == 'getUserResponse') {
          final userData = data['data'];
          if (userData != null) {
            final availabilityStatus = userData['availability_status'];

            log(
              "📊 GetUser response received - Availability Status: $availabilityStatus",
            );

            // Update local storage with new availability status
            _updateUserProfileFromWebSocket(userData);
          }
        }
      }
    } catch (e) {
      log("❌ Error handling WebSocket message: $e");
    }
  }

  // Update user status based on WebSocket response
  void _updateUserStatus(bool isOnline) async {
    try {
      final userData = await UserStorageService.getUserData();
      if (userData != null && userData.user != null) {
        // Use the actual response status, not local storage
        emit(ProfileLoaded(user: userData.user!, isOnline: isOnline));

        log(
          "✅ User status updated to: ${isOnline ? 'Online' : 'Offline'} (from WebSocket response)",
        );
      }
    } catch (e) {
      log("❌ Error updating user status: $e");
    }
  }

  // Update user profile from WebSocket getUser response
  void _updateUserProfileFromWebSocket(Map<String, dynamic> userData) async {
    try {
      final availabilityStatus =
          userData['availability_status']?.toString() ?? "0";

      // Update availability status in local storage
      await UserStorageService.updateAvailabilityStatus(availabilityStatus);

      // Get updated user data and emit state directly (avoid infinite recursion)
      final updatedUserData = await UserStorageService.getUserData();
      if (updatedUserData != null && updatedUserData.user != null) {
        final isOnline = availabilityStatus == "1";
        emit(ProfileLoaded(user: updatedUserData.user!, isOnline: isOnline));
      }

      log(
        "✅ User profile updated from WebSocket response - Status: $availabilityStatus",
      );
    } catch (e) {
      log("❌ Error updating user profile from WebSocket: $e");
    }
  }

  // Send status update via shared WebSocket
  Future<void> _sendStatusUpdate(int userId, int status) async {
    final success = await _sharedWebSocket.sendStatusUpdate(userId, status);
    if (success) {
      log("📤 Status update sent successfully");
    } else {
      log("❌ Failed to send status update");
    }
  }

  Future<void> updateAvailabilityStatus(bool isOnDuty) async {
    final userData = await UserStorageService.getUserData();
    if (userData != null && userData.user != null) {
      final userId = userData.user!.id;
      final status = isOnDuty ? 1 : 0;

      // Send status update via shared WebSocket
      await _sendStatusUpdate(userId, status);

      // Small delay to ensure WebSocket message is processed
      await Future.delayed(Duration(milliseconds: 500));

      // Refresh user profile from server to get the actual status
      await _refreshUserProfile();
    }
  }

  // Refresh user profile from server via WebSocket
  Future<void> _refreshUserProfile() async {
    try {
      final userData = await UserStorageService.getUserData();
      if (userData != null && userData.user != null) {
        final userId = userData.user!.id;

        // Send getUser request via shared WebSocket
        final success = await _sharedWebSocket.sendGetUserRequest(userId);
        if (success) {
          log("📤 GetUser request sent via shared WebSocket");
        } else {
          log("❌ Failed to send GetUser request");
        }
      }
    } catch (e) {
      log("❌ Error refreshing user profile: $e");
      // Fallback to local data
      await fetchUserData();
    }
  }

  // Disconnect WebSocket when cubit is disposed
  void disconnectWebSocket() {
    _sharedWebSocket.removeMessageListener(_handleWebSocketMessage);
    log("🔌 Removed message listener from shared WebSocket");
  }

  @override
  Future<void> close() {
    disconnectWebSocket();
    return super.close();
  }
}
