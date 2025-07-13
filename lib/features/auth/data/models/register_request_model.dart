class RegisterRequestModel {
  final String name;
  final String email;
  final String password;
  final String? confirmPassword;
  final String? fullName;
  final String? mobile_number;
  final String? role;
  final String? driverType;
  final String? branchCode;

  RegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
    this.confirmPassword,
    this.fullName,
    this.mobile_number,
    this.role,
    this.driverType,
    this.branchCode,
  });

  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    return RegisterRequestModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      confirmPassword: json['confirm_password'],
      fullName: json['full_name'],
      mobile_number: json['mobile_number'],
      role: json['role'],
      driverType: json['driver_type'],
      branchCode: json['branch_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (confirmPassword != null) 'confirm_password': confirmPassword,
      if (fullName != null) 'full_name': fullName,
      if (mobile_number != null) 'mobile_number': mobile_number,
      if (role != null) 'role': role,
      if (driverType != null) 'driver_type': driverType,
      if (branchCode != null) 'branch_code': branchCode,
    };
  }
}
