import 'package:api_gateway/api_gateway.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';

class AuthRemoteDatasource {
  final ApiGateway apiGateway;

  AuthRemoteDatasource({required this.apiGateway});

  Future<LoginResponseModel> login(LoginRequestModel loginRequestModel) async {
    final response = await apiGateway.login(
      loginRequestModel.email,
      loginRequestModel.password,
    );
    return LoginResponseModel.fromJson(response.data);
  }
}
