import '../../data/models/register_request_model.dart';
import '../../data/models/register_response_model.dart';
import '../repositories/auth_repository.dart';

class RegisterCases {
  final AuthRepository authRepository;

  RegisterCases({required this.authRepository});

  Future<RegisterResponseModel> register(
    RegisterRequestModel registerRequestModel,
  ) async {
    return await authRepository.register(registerRequestModel);
  }
}
