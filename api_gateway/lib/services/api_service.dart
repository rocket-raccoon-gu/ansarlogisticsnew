import 'dart:developer';

import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/api_config.dart';

class ApiService {
  final HttpClient _httpClient;
  final WebSocketClient _wsClient;

  ApiService(this._httpClient, this._wsClient);

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

  Future<void> connectWebSocket() async {
    _wsClient.connect(ApiConfig.wsUrl);
  }

  Future<void> sendLocation(double lat, double lng) async {
    _wsClient.connect(ApiConfig.wsUrl);
    _wsClient.send(jsonEncode({'latitude': lat, 'longitude': lng}));
  }

  Future<Response> getOrders(String token) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.baseUrl}picker/orders',
        queryParameters: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token}',
        },
      );
      log('Orders response status: ${response.statusCode}');
      log('Orders response data: ${response.data}');
      return response;
    } catch (e) {
      log('Orders error: $e.toString()');
      rethrow;
    }
  }

  Future<dynamic> fetchPickerOrderDetails(String orderId, String token) async {
    final response = await _httpClient.get(
      '${ApiConfig.baseUrl}picker/orders/$orderId',
      queryParameters: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.data != null) {
      return response.data['data'];
    } else {
      throw Exception('No data found for order');
    }
  }

  Future<dynamic> updateAvailabilityStatus(int status, int id) async {
    final dio = Dio();
    final response = await dio.put(
      '${ApiConfig.baseUrl}/pd_online_status.php',
      data: {'status': status, 'user_id': id},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        followRedirects: false,
        validateStatus: (status) => true,
      ),
    );
    log('Update availability status response status: ${response.statusCode}');
    log('Update availability status response data: ${response.data}');
    return response;
  }
}
