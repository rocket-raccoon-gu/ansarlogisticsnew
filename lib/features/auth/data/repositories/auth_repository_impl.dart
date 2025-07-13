import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';
import '../models/info_data_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;

  AuthRepositoryImpl({required this.authRemoteDatasource});

  @override
  Future<LoginResponseModel> login(LoginRequestModel loginRequestModel) async {
    return await authRemoteDatasource.login(loginRequestModel);
  }

  @override
  Future<RegisterResponseModel> register(
    RegisterRequestModel registerRequestModel,
  ) async {
    return await authRemoteDatasource.register(registerRequestModel);
  }

  @override
  Future<InfoDataResponseModel> getInfoData() async {
    return await authRemoteDatasource.getInfoData();
  }
}
