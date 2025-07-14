part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final LoginResponseModel loginResponseModel;
  final UserRole userRole;

  AuthSuccess({required this.loginResponseModel, required this.userRole});
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure({required this.error});
}
