import 'package:ansarlogisticsnew/features/auth/data/models/register_request_model.dart';
import 'package:ansarlogisticsnew/features/auth/data/models/register_response_model.dart';
import 'package:ansarlogisticsnew/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCases {
  final AuthRepository authRepository;

  RegisterUseCases({required this.authRepository});

  Future<RegisterResponseModel> register(
    RegisterRequestModel registerRequestModel,
  ) async {
    return await authRepository.register(registerRequestModel);
  }
}
