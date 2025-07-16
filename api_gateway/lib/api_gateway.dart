import 'package:api_gateway/services/api_service.dart';

class ApiGateway {
  final ApiService _apiService;

  ApiGateway({required ApiService apiService}) : _apiService = apiService;

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

  Future<dynamic> updateAvailabilityStatus(int status, int id) async {
    return await _apiService.updateAvailabilityStatus(status, id);
  }
}
