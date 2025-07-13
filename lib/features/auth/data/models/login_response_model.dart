class LoginResponseModel {
  final bool success;
  final String? token;
  final String? message;
  final UserModel? user;

  LoginResponseModel({
    required this.success,
    this.token,
    this.message,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] ?? false,
      token: json['token'],
      message: json['message'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'token': token,
      'message': message,
      'user': user?.toJson(),
    };
  }
}

class UserModel {
  final int id;
  final String empId;
  final String employeeId;
  final String name;
  final String distance;
  final String latitude;
  final String longitude;
  final int status;
  final int approveStatus;
  final String email;
  final String mobileNumber;
  final String vehicleNumber;
  final int availabilityStatus;
  final int breakStatus;
  final String vehicleType;
  final String password;
  final String address;
  final int role;
  final String driverType;
  final int zoneFlag;
  final String branchCode;
  final String categoryIds;
  final String regularShiftTime;
  final String fridayShiftTime;
  final String offDay;
  final int orderLimit;
  final String appVersion;
  final String createdAt;
  final String updatedAt;
  final String? rpToken;
  final String rpTokenCreatedAt;

  UserModel({
    required this.id,
    required this.empId,
    required this.employeeId,
    required this.name,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.approveStatus,
    required this.email,
    required this.mobileNumber,
    required this.vehicleNumber,
    required this.availabilityStatus,
    required this.breakStatus,
    required this.vehicleType,
    required this.password,
    required this.address,
    required this.role,
    required this.driverType,
    required this.zoneFlag,
    required this.branchCode,
    required this.categoryIds,
    required this.regularShiftTime,
    required this.fridayShiftTime,
    required this.offDay,
    required this.orderLimit,
    required this.appVersion,
    required this.createdAt,
    required this.updatedAt,
    this.rpToken,
    required this.rpTokenCreatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      empId: json['emp_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      name: json['name'] ?? '',
      distance: json['distance'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      status: json['status'] ?? 0,
      approveStatus: json['approve_status'] ?? 0,
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      availabilityStatus: json['availability_status'] ?? 0,
      breakStatus: json['break_status'] ?? 0,
      vehicleType: json['vehicle_type'] ?? '',
      password: json['password'] ?? '',
      address: json['address'] ?? '',
      role: json['role'] ?? 0,
      driverType: json['driver_type'] ?? '',
      zoneFlag: json['zone_flag'] ?? 0,
      branchCode: json['branch_code'] ?? '',
      categoryIds: json['category_ids'] ?? '',
      regularShiftTime: json['regular_shift_time'] ?? '',
      fridayShiftTime: json['friday_shift_time'] ?? '',
      offDay: json['off_day'] ?? '',
      orderLimit: json['order_limit'] ?? 0,
      appVersion: json['app_version'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      rpToken: json['rp_token'],
      rpTokenCreatedAt: json['rp_token_created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emp_id': empId,
      'employee_id': employeeId,
      'name': name,
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'approve_status': approveStatus,
      'email': email,
      'mobile_number': mobileNumber,
      'vehicle_number': vehicleNumber,
      'availability_status': availabilityStatus,
      'break_status': breakStatus,
      'vehicle_type': vehicleType,
      'password': password,
      'address': address,
      'role': role,
      'driver_type': driverType,
      'zone_flag': zoneFlag,
      'branch_code': branchCode,
      'category_ids': categoryIds,
      'regular_shift_time': regularShiftTime,
      'friday_shift_time': fridayShiftTime,
      'off_day': offDay,
      'order_limit': orderLimit,
      'app_version': appVersion,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'rp_token': rpToken,
      'rp_token_created_at': rpTokenCreatedAt,
    };
  }
}
