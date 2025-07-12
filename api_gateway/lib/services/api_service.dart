import 'package:api_gateway/http/http_client.dart';

class ApiService {
  final HttpClient _httpClient;

  ApiService(this._httpClient);

  Future<dynamic> login(String email, String password) async {
    return await _httpClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  Future<dynamic> fetchProfile() async {
    return await _httpClient.get('/profile');
  }
}
