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

  Future<dynamic> login(String email, String password) async {
    return await _apiService.login(email, password);
  }
}
