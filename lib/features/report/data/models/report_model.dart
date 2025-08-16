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
  final int holdedOrders;
  final int materialRequestOrders;
  final int cancelRequestOrders;

  PickerReportModel({
    required super.role,
    required super.assignedOrders,
    required super.startedOrders,
    required super.completedOrders,
    required super.fromDate,
    required super.toDate,
    required this.endPickedOrders,
    this.holdedOrders = 0,
    this.materialRequestOrders = 0,
    this.cancelRequestOrders = 0,
  });

  factory PickerReportModel.fromJson(Map<String, dynamic> json) {
    return PickerReportModel(
      role: json['role'] ?? 'picker',
      assignedOrders: json['assigned_orders'] ?? 0,
      startedOrders: json['started_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      endPickedOrders: json['end_picked_orders'] ?? 0,
      holdedOrders: json['holded_orders'] ?? 0,
      materialRequestOrders: json['material_request_orders'] ?? 0,
      cancelRequestOrders: json['cancel_request_orders'] ?? 0,
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
      'end_picked_orders': endPickedOrders,
      'holded_orders': holdedOrders,
      'material_request_orders': materialRequestOrders,
      'cancel_request_orders': cancelRequestOrders,
    };
  }
}

class DriverReportModel extends ReportModel {
  final int onTheWayOrders;
  final int deliveredOrders;
  final int orderCollectedOrders;
  final int customerNotAnswerOrders;
  final int cancelRequestOrders;
  final int materialRequestOrders;

  DriverReportModel({
    required super.role,
    required super.assignedOrders,
    required super.startedOrders,
    required super.completedOrders,
    required super.fromDate,
    required super.toDate,
    required this.onTheWayOrders,
    required this.deliveredOrders,
    this.orderCollectedOrders = 0,
    this.customerNotAnswerOrders = 0,
    this.cancelRequestOrders = 0,
    this.materialRequestOrders = 0,
  });

  factory DriverReportModel.fromJson(Map<String, dynamic> json) {
    return DriverReportModel(
      role: json['role'] ?? 'driver',
      assignedOrders: json['assigned_orders'] ?? 0,
      startedOrders: json['started_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      onTheWayOrders: json['on_the_way_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      orderCollectedOrders: json['order_collected_orders'] ?? 0,
      customerNotAnswerOrders: json['customer_not_answer_orders'] ?? 0,
      cancelRequestOrders: json['cancel_request_orders'] ?? 0,
      materialRequestOrders: json['material_request_orders'] ?? 0,
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
      'order_collected_orders': orderCollectedOrders,
      'customer_not_answer_orders': customerNotAnswerOrders,
      'cancel_request_orders': cancelRequestOrders,
      'material_request_orders': materialRequestOrders,
    };
  }
}

// New model for picker report API response
class PickerReportDataModel {
  final bool success;
  final int count;
  final List<PickerReportItemModel> data;

  PickerReportDataModel({
    required this.success,
    required this.count,
    required this.data,
  });

  factory PickerReportDataModel.fromJson(Map<String, dynamic> json) {
    return PickerReportDataModel(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => PickerReportItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }

  // Helper method to convert to PickerReportModel
  PickerReportModel toPickerReportModel(DateTime fromDate, DateTime toDate) {
    int assignedOrders = 0;
    int startedOrders = 0;
    int completedOrders = 0;
    int endPickedOrders = 0;
    int holdedOrders = 0;
    int materialRequestOrders = 0;
    int cancelRequestOrders = 0;

    for (var item in data) {
      switch (item.status) {
        case 'assigned_picker':
          assignedOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'start_picking':
          startedOrders = int.tryParse(item.orderCount) ?? 0;
          break;

        case 'end_picking':
          endPickedOrders = int.tryParse(item.orderCount) ?? 0;
          completedOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'holded':
          holdedOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'material_request':
          materialRequestOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'cancel_request':
          cancelRequestOrders = int.tryParse(item.orderCount) ?? 0;
          break;
      }
    }

    return PickerReportModel(
      role: 'picker',
      assignedOrders: assignedOrders,
      startedOrders: startedOrders,
      completedOrders: completedOrders,
      endPickedOrders: endPickedOrders,
      holdedOrders: holdedOrders,
      materialRequestOrders: materialRequestOrders,
      cancelRequestOrders: cancelRequestOrders,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}

class PickerReportItemModel {
  final String orderCount;
  final String status;
  final DateTime createdAt;

  PickerReportItemModel({
    required this.orderCount,
    required this.status,
    required this.createdAt,
  });

  factory PickerReportItemModel.fromJson(Map<String, dynamic> json) {
    return PickerReportItemModel(
      orderCount: json['order_count'] ?? '0',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_count': orderCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// New model for driver report API response
class DriverReportDataModel {
  final bool success;
  final int count;
  final List<DriverReportItemModel> data;

  DriverReportDataModel({
    required this.success,
    required this.count,
    required this.data,
  });

  factory DriverReportDataModel.fromJson(Map<String, dynamic> json) {
    return DriverReportDataModel(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => DriverReportItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }

  // Helper method to convert to DriverReportModel
  DriverReportModel toDriverReportModel(DateTime fromDate, DateTime toDate) {
    int assignedOrders = 0;
    int startedOrders = 0;
    int completedOrders = 0;
    int onTheWayOrders = 0;
    int deliveredOrders = 0;
    int orderCollectedOrders = 0;
    int cancelRequestOrders = 0;
    int materialRequestOrders = 0;
    int customerNotAnswerOrders = 0;

    for (var item in data) {
      switch (item.status) {
        case 'assigned_driver':
          assignedOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'on_the_way':
          onTheWayOrders = int.tryParse(item.orderCount) ?? 0;
          startedOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'complete':
          completedOrders = int.tryParse(item.orderCount) ?? 0;
          deliveredOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'order_collected':
          orderCollectedOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'cancel_request':
          cancelRequestOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'material_request':
          materialRequestOrders = int.tryParse(item.orderCount) ?? 0;
          break;
        case 'customer_not_answer':
          customerNotAnswerOrders = int.tryParse(item.orderCount) ?? 0;
          break;
      }
    }

    return DriverReportModel(
      role: 'driver',
      assignedOrders: assignedOrders,
      startedOrders: startedOrders,
      completedOrders: completedOrders,
      onTheWayOrders: onTheWayOrders,
      deliveredOrders: deliveredOrders,
      orderCollectedOrders: orderCollectedOrders,
      customerNotAnswerOrders: customerNotAnswerOrders,
      cancelRequestOrders: cancelRequestOrders,
      materialRequestOrders: materialRequestOrders,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}

class DriverReportItemModel {
  final String orderCount;
  final String status;
  final DateTime createdAt;

  DriverReportItemModel({
    required this.orderCount,
    required this.status,
    required this.createdAt,
  });

  factory DriverReportItemModel.fromJson(Map<String, dynamic> json) {
    return DriverReportItemModel(
      orderCount: json['order_count'] ?? '0',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_count': orderCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
