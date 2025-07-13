import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/login_response_model.dart';
import '../../domain/usecases/login_cases.dart';

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
        emit(AuthSuccess(loginResponseModel: loginResponseModel));
      } else {
        // API returned success: false with an error message
        emit(AuthFailure(error: loginResponseModel.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
}
