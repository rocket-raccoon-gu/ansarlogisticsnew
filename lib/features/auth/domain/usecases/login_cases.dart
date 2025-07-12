import '../../data/models/login_request_model.dart';
import '../../data/models/login_response_model.dart';
import '../repositories/auth_repository.dart';

class LoginCases {
  final AuthRepository authRepository;

  LoginCases({required this.authRepository});

  Future<LoginResponseModel> login(LoginRequestModel loginRequestModel) async {
    return await authRepository.login(loginRequestModel);
  }
}
