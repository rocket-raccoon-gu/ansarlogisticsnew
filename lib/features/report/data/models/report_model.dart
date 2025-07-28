class ReportModel {
  final String role;
  final int assignedOrders;
  final int startedOrders;
  final int completedOrders;
  final DateTime fromDate;
  final DateTime toDate;

  ReportModel({
    required this.role,
    required this.assignedOrders,
    required this.startedOrders,
    required this.completedOrders,
    required this.fromDate,
    required this.toDate,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      role: json['role'] ?? '',
      assignedOrders: json['assigned_orders'] ?? 0,
      startedOrders: json['started_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      fromDate: DateTime.parse(
        json['from_date'] ?? DateTime.now().toIso8601String(),
      ),
      toDate: DateTime.parse(
        json['to_date'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'assigned_orders': assignedOrders,
      'started_orders': startedOrders,
      'completed_orders': completedOrders,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? role,
    int? assignedOrders,
    int? startedOrders,
    int? completedOrders,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ReportModel(
      role: role ?? this.role,
      assignedOrders: assignedOrders ?? this.assignedOrders,
      startedOrders: startedOrders ?? this.startedOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

class PickerReportModel extends ReportModel {
  final int endPickedOrders;

  PickerReportModel({
    required super.role,
    required super.assignedOrders,
    required super.startedOrders,
    required super.completedOrders,
    required super.fromDate,
    required super.toDate,
    required this.endPickedOrders,
  });

  factory PickerReportModel.fromJson(Map<String, dynamic> json) {
    return PickerReportModel(
      role: json['role'] ?? 'picker',
      assignedOrders: json['assigned_orders'] ?? 0,
      startedOrders: json['started_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      endPickedOrders: json['end_picked_orders'] ?? 0,
      fromDate: DateTime.parse(
        json['from_date'] ?? DateTime.now().toIso8601String(),
      ),
      toDate: DateTime.parse(
        json['to_date'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), 'end_picked_orders': endPickedOrders};
  }
}

class DriverReportModel extends ReportModel {
  final int onTheWayOrders;
  final int deliveredOrders;

  DriverReportModel({
    required super.role,
    required super.assignedOrders,
    required super.startedOrders,
    required super.completedOrders,
    required super.fromDate,
    required super.toDate,
    required this.onTheWayOrders,
    required this.deliveredOrders,
  });

  factory DriverReportModel.fromJson(Map<String, dynamic> json) {
    return DriverReportModel(
      role: json['role'] ?? 'driver',
      assignedOrders: json['assigned_orders'] ?? 0,
      startedOrders: json['started_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      onTheWayOrders: json['on_the_way_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      fromDate: DateTime.parse(
        json['from_date'] ?? DateTime.now().toIso8601String(),
      ),
      toDate: DateTime.parse(
        json['to_date'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'on_the_way_orders': onTheWayOrders,
      'delivered_orders': deliveredOrders,
    };
  }
}
