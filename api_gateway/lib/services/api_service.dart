import 'dart:developer';
import 'dart:io';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/api_config.dart';
import 'package:http_parser/http_parser.dart';

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

  Future<dynamic> updateOrderStatus(
    String status,
    String preparationId,
    String token, {
    String? orderNumber,
    String? cancelReason,
  }) async {
    try {
      final dio = Dio();
      final data = {
        'status': status,
        'preparation_id': preparationId,
        'comment': cancelReason,
      };
      if (orderNumber != null) data['order_number'] = orderNumber;
      if (cancelReason != null) data['cancel_reason'] = cancelReason;

      final response = await dio.patch(
        '${ApiConfig.baseUrl}picker/orders/status',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      log('Update order status response status: ${response.statusCode}');
      log('Update order status response data: ${response.data}');
      return response;
    } catch (e) {
      log('Update order status error: $e.toString()');
      rethrow;
    }
  }

  Future<dynamic> updateOrderStatusDriver(
    String token,
    String preparationId,
    String orderStatus,
  ) async {
    try {
      log('Mark order as $orderStatus: $token, $preparationId');
      final dio = Dio();
      final response = await dio.patch(
        '${ApiConfig.baseUrl}driver/orders/status/$preparationId',
        data: {'status': orderStatus},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      log('Mark order as $orderStatus response status: ${response.statusCode}');
      log('Mark order as $orderStatus response data: ${response.data}');
      return response;
    } catch (e) {
      log('Mark order as $orderStatus error: $e.toString()');
      rethrow;
    }
  }

  Future<dynamic> uploadBill(
    String orderId,
    File imageFile,
    String token,
    double latitude,
    double longitude,
  ) async {
    try {
      log('Uploading bill for order: $orderId');
      final dio = Dio();

      // Create form data
      final formData = FormData.fromMap({
        'bill': await MultipartFile.fromFile(
          imageFile.path,
          filename:
              'bill_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType.parse('image/jpeg'),
        ),
        'status': 'complete',
        'latitude': latitude,
        'longitude': longitude,
      });

      log('Upload bill data: ${formData.fields}');

      final response = await dio.put(
        '${ApiConfig.baseUrl}driver/orders/status/$orderId',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      log('Upload bill response status: ${response.statusCode}');
      log('Upload bill response data: ${response.data}');
      return response;
    } catch (e) {
      log('Upload bill error: $e.toString()');
      rethrow;
    }
  }

  Future<dynamic> scanBarcodeAndPickItem(
    String sku,
    String token,
    String orderSku,
  ) async {
    try {
      final dio = Dio();
      log('Scan barcode and pick item: $orderSku, $token, $sku');
      final response = await dio.post(
        '${ApiConfig.baseUrl}picker/orders/check-sku',
        data: {'sku': sku, 'skuAction': 'pick', 'skuOrder': orderSku},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      log('Scan barcode response status: ${response.statusCode}');
      log('Scan barcode response data: ${response.data}');
      return response;
    } catch (e) {
      log('Scan barcode error: $e.toString()');
      rethrow;
    }
  }

  Future<dynamic> getProductBySku(String sku, String token) async {
    try {
      final response = await _httpClient.post(
        '${ApiConfig.baseUrl}picker/orders/check-sku',
        data: {'sku': sku},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      log('Get product by sku response status: ${response.statusCode}');
      log('Get product by sku response data: ${response.data}');
      return response;
    } catch (e) {
      log('Get product by sku error: $e.toString()');
      rethrow;
    }
  }

  Future<dynamic> updateItemStatus({
    required int itemId,
    required String scannedSku,
    required String status,
    required String price,
    required String qty,
    required String preparationId,
    required int isProduce,
    String? reason,
    required String token,
    String? productName,
    int? productId,
    required String orderNumber,
  }) async {
    try {
      final dio = Dio();
      log('Update item status: $itemId, $scannedSku, $status, $qty');

      final data = {
        'item_id': itemId,
        'order_number': orderNumber,
        'scanned_sku': scannedSku,
        'status': status,
        'price': price,
        'qty': qty,
        'preparation_id': preparationId,
        'is_produce': isProduce,
        'productId': productId ?? 0,
        'name': productName ?? '',
        if (reason != null) 'reason': reason,
      };
      log('Update item status data: $data');

      final response = await dio.patch(
        '${ApiConfig.baseUrl}picker/orders/item/status',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      log('Update item status response status: ${response.statusCode}');
      log('Update item status response data: ${response.data}');
      return response;
    } catch (e) {
      log('Update item status error: $e.toString()');
      rethrow;
    }
  }

  Future<Response> getDriverOrders(String token) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.baseUrl}driver/orders',
        queryParameters: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log('Driver Orders response status: ${response.statusCode}');
      log('Driver Orders response data: ${response.data}');
      return response;
    } catch (e) {
      log('Driver Orders error: ${e.toString()}');
      rethrow;
    }
  }

  Future<Response> getDriverOrderDetails(String orderId, String token) async {
    try {
      final response = await _httpClient.get(
        '${ApiConfig.baseUrl}driver/orders/$orderId',
        queryParameters: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log('Driver Order Details response status:  {response.statusCode}');
      log('Driver Order Details response data:  {response.data}');
      return response;
    } catch (e) {
      log('Driver Order Details error:  {e.toString()}');
      rethrow;
    }
  }

  Future<Response> getReport({
    required String token,
    required String role,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${ApiConfig.baseUrl}reports/$role',
        queryParameters: {
          'from_date': fromDate.toIso8601String(),
          'to_date': toDate.toIso8601String(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      log('Report response status: ${response.statusCode}');
      log('Report response data: ${response.data}');
      return response;
    } catch (e) {
      log('Report error: ${e.toString()}');
      rethrow;
    }
  }
}
