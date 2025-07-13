class LoginRequestModel {
  final String username;
  final String password;
  final String? device_token;
  final String? version;

  LoginRequestModel({
    required this.username,
    required this.password,
    this.device_token,
    this.version,
  });

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      username: json['username'],
      password: json['password'],
      device_token: json['device_token'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      if (device_token != null) 'device_token': device_token,
      if (version != null) 'version': version,
    };
  }
}
