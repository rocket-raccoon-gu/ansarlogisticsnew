class RegisterResponseModel {
  final bool success;
  final String? message;

  RegisterResponseModel({required this.success, this.message});

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message};
  }
}
