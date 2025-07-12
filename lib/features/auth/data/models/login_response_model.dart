class LoginResponseModel {
  final String token;
  final String userId;

  LoginResponseModel({required this.token, required this.userId});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(token: json['token'], userId: json['userId']);
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'userId': userId};
  }
}
