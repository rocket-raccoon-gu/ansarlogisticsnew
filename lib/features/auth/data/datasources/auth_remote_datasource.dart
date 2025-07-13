import 'package:api_gateway/api_gateway.dart';
import 'package:dio/dio.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';
import '../models/info_data_response_model.dart';

class AuthRemoteDatasource {
  final ApiGateway apiGateway;

  AuthRemoteDatasource({required this.apiGateway});

  Future<LoginResponseModel> login(LoginRequestModel loginRequestModel) async {
    try {
      final response = await apiGateway.login(
        loginRequestModel.username, // Changed from username to email
        loginRequestModel.password,
        fcmToken: loginRequestModel.device_token,
        version: loginRequestModel.version,
      );
      return LoginResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Return a proper error response model
        return LoginResponseModel(
          success: false,
          message: 'Invalid credentials. Please check your email and password.',
        );
      }
      // For other network errors
      return LoginResponseModel(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      // For any other errors
      return LoginResponseModel(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  Future<RegisterResponseModel> register(
    RegisterRequestModel registerRequestModel,
  ) async {
    try {
      final response = await apiGateway.register(registerRequestModel.toJson());
      return RegisterResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Return a proper error response model
        return RegisterResponseModel(
          success: false,
          message: 'Registration failed. Please check your information.',
        );
      }
      // For other network errors
      return RegisterResponseModel(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      // For any other errors
      return RegisterResponseModel(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  Future<InfoDataResponseModel> getInfoData() async {
    try {
      final response = await apiGateway.getInfoData();
      return InfoDataResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      // Return empty data on error
      return InfoDataResponseModel(
        success: false,
        roles: {},
        companies: [],
        branches: {},
      );
    } catch (e) {
      // Return empty data on error
      return InfoDataResponseModel(
        success: false,
        roles: {},
        companies: [],
        branches: {},
      );
    }
  }
}
