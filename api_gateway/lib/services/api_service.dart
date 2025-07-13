import 'package:api_gateway/http/http_client.dart';
import 'package:dio/dio.dart';

class ApiService {
  final HttpClient _httpClient;

  ApiService(this._httpClient);

  Future<dynamic> login(
    String username,
    String password, {
    String? fcmToken,
    String? version,
  }) async {
    try {
      print('Attempting login with email: $username');

      // Try the login endpoint
      final response = await _httpClient.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          if (fcmToken != null) 'device_token': fcmToken,
          if (version != null) 'version': version,
        },
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Login error: ${e.message}');
      print('Login error status: ${e.response?.statusCode}');
      print('Login error data: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        // Handle 401 Unauthorized error
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Invalid credentials. Please check your email and password.',
        );
      }
      rethrow;
    }
  }

  Future<dynamic> register(Map<String, dynamic> registerData) async {
    try {
      print('Attempting registration with data: $registerData');

      final response = await _httpClient.post(
        '/auth/register',
        data: registerData,
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Registration error: ${e.message}');
      print('Registration error status: ${e.response?.statusCode}');
      print('Registration error data: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        // Handle 400 Bad Request error
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Registration failed. Please check your information.',
        );
      }
      rethrow;
    }
  }

  Future<dynamic> getInfoData() async {
    try {
      print('Fetching info data');

      final response = await _httpClient.get('/auth/infodata');

      print('Info data response status: ${response.statusCode}');
      print('Info data response data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Info data error: ${e.message}');
      print('Info data error status: ${e.response?.statusCode}');
      print('Info data error data: ${e.response?.data}');
      rethrow;
    }
  }

  // Alternative login method with different endpoint
  Future<dynamic> loginAlternative(String username, String password) async {
    try {
      print('Attempting login with alternative endpoint');

      final response = await _httpClient.post(
        '/login', // Try without /auth prefix
        data: {'email': username, 'password': password},
      );

      print('Alternative login response status: ${response.statusCode}');
      print('Alternative login response data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Alternative login error: ${e.message}');
      print('Alternative login error status: ${e.response?.statusCode}');
      print('Alternative login error data: ${e.response?.data}');
      rethrow;
    }
  }

  Future<dynamic> fetchProfile() async {
    return await _httpClient.get('/profile');
  }
}
