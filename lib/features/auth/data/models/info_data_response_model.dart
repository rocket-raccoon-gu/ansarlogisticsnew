class InfoDataResponseModel {
  final bool success;
  final Map<String, String> roles;
  final List<CompanyModel> companies;
  final Map<String, String> branches;

  InfoDataResponseModel({
    required this.success,
    required this.roles,
    required this.companies,
    required this.branches,
  });

  factory InfoDataResponseModel.fromJson(Map<String, dynamic> json) {
    return InfoDataResponseModel(
      success: json['success'] ?? false,
      roles: Map<String, String>.from(json['roles'] ?? {}),
      companies:
          (json['companies'] as List<dynamic>?)
              ?.map((company) => CompanyModel.fromJson(company))
              .toList() ??
          [],
      branches: Map<String, String>.from(json['branches'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'roles': roles,
      'companies': companies.map((company) => company.toJson()).toList(),
      'branches': branches,
    };
  }
}

class CompanyModel {
  final int id;
  final String name;
  final String address;
  final String email;
  final String phoneNumber;
  final String createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'email': email,
      'phone_number': phoneNumber,
      'created_at': createdAt,
    };
  }
}
