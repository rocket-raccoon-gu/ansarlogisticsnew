import '../../data/models/login_request_model.dart';
import '../../data/models/login_response_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/register_response_model.dart';
import '../../data/models/info_data_response_model.dart';

abstract class AuthRepository {
  Future<LoginResponseModel> login(LoginRequestModel loginRequestModel);

  Future<RegisterResponseModel> register(
    RegisterRequestModel registerRequestModel,
  );
  Future<InfoDataResponseModel> getInfoData();
}
