import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/ws/websockt_client.dart';

class ApiGateway {
  final HttpClient _httpClient;
  final WebSocketClient _webSocketClient;
  final ApiService _apiService;

  ApiGateway({
    required HttpClient httpClient,
    required WebSocketClient webSocketClient,
    required ApiService apiService,
  }) : _httpClient = httpClient,
       _webSocketClient = webSocketClient,
       _apiService = apiService;

  Future<dynamic> login(
    String username,
    String password, {
    String? fcmToken,
    String? version,
  }) async {
    return await _apiService.login(
      username,
      password,
      fcmToken: fcmToken,
      version: version,
    );
  }

  Future<dynamic> register(Map<String, dynamic> registerData) async {
    return await _apiService.register(registerData);
  }

  Future<dynamic> getInfoData() async {
    return await _apiService.getInfoData();
  }

  Future<dynamic> loginAlternative(String username, String password) async {
    return await _apiService.loginAlternative(username, password);
  }
}
