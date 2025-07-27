part of 'profile_cubit.dart';

abstract class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final dynamic user; // Use your User model type if available
  final bool isOnline; // Track online/offline status from WebSocket
  ProfileLoaded({required this.user, this.isOnline = true});
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
