import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/login_response_model.dart';
import '../../domain/usecases/login_cases.dart';
import '../../../../core/utils/role_utils.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../navigation/presentation/cubit/bottom_navigation_cubit.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/driver_location_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginCases loginCases;

  AuthCubit({required this.loginCases}) : super(AuthInitial());

  Future<void> login(LoginRequestModel loginRequestModel) async {
    emit(AuthLoading());
    try {
      final loginResponseModel = await loginCases.login(loginRequestModel);

      // Check if the response indicates success or failure
      if (loginResponseModel.success) {
        // Determine user role from the response
        final userRole = RoleUtils.getUserRoleFromApi(
          loginResponseModel.user?.role ?? 0,
          loginResponseModel.user?.driverType ?? '',
        );

        // Save user data to SharedPreferences
        await UserStorageService.saveUserData(loginResponseModel);

        // Start driver location tracking if the user is a driver
        if (userRole == UserRole.driver) {
          DriverLocationService().startTracking();
        }

        emit(
          AuthSuccess(
            loginResponseModel: loginResponseModel,
            userRole: userRole,
          ),
        );
      } else {
        // API returned success: false with an error message
        emit(AuthFailure(error: loginResponseModel.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
}
