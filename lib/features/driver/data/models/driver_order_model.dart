import 'dart:convert';

class DriverOrderModel {
  final String id;
  final double orderSubTotalValue;
  final double totalOrderValue;
  final String orderStatus;
  final String orderStatusTxt;
  final String driverStatus;
  final String driverStatusTxt;
  final int customerId;
  final int deliveryToId;
  final String? acceptedAt;
  final String? pickedupAt;
  final String? deliveredAt;
  final DriverOrderLocation pickup;
  final DriverOrderLocation dropoff;
  final DriverOrderCustomer customer;
  final List<DriverOrderItem> items;

  DriverOrderModel({
    required this.id,
    required this.orderSubTotalValue,
    required this.totalOrderValue,
    required this.orderStatus,
    required this.orderStatusTxt,
    required this.driverStatus,
    required this.driverStatusTxt,
    required this.customerId,
    required this.deliveryToId,
    this.acceptedAt,
    this.pickedupAt,
    this.deliveredAt,
    required this.pickup,
    required this.dropoff,
    required this.customer,
    required this.items,
  });

  factory DriverOrderModel.fromJson(Map<String, dynamic> json) {
    return DriverOrderModel(
      id: json['id']?.toString() ?? '',
      orderSubTotalValue:
          (json['order_sub_total_value'] as num?)?.toDouble() ?? 0.0,
      totalOrderValue: (json['total_order_value'] as num?)?.toDouble() ?? 0.0,
      orderStatus: json['order_status']?.toString() ?? '',
      orderStatusTxt: json['order_status_txt']?.toString() ?? '',
      driverStatus: json['driver_status']?.toString() ?? '',
      driverStatusTxt: json['driver_status_txt']?.toString() ?? '',
      customerId:
          json['customer_id'] is int
              ? json['customer_id']
              : int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      deliveryToId:
          json['delivery_to_id'] is int
              ? json['delivery_to_id']
              : int.tryParse(json['delivery_to_id']?.toString() ?? '0') ?? 0,
      acceptedAt: json['accepted_at']?.toString(),
      pickedupAt: json['pickedup_at']?.toString(),
      deliveredAt: json['delivered_at']?.toString(),
      pickup: DriverOrderLocation.fromJson(json['pickup'] ?? {}),
      dropoff: DriverOrderLocation.fromJson(json['dropoff'] ?? {}),
      customer: DriverOrderCustomer.fromJson(json['customer'] ?? {}),
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    DriverOrderItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  static List<DriverOrderModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((e) => DriverOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class DriverOrderLocation {
  final String name;
  final String latitude;
  final String longitude;
  final String zone;
  final String street;
  final String building;

  DriverOrderLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.street,
    required this.building,
  });

  factory DriverOrderLocation.fromJson(Map<String, dynamic> json) {
    return DriverOrderLocation(
      name: json['name']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      building: json['building']?.toString() ?? '',
    );
  }
}

class DriverOrderCustomer {
  final String name;
  final String mobileNumber;

  DriverOrderCustomer({required this.name, required this.mobileNumber});

  factory DriverOrderCustomer.fromJson(Map<String, dynamic> json) {
    return DriverOrderCustomer(
      name: json['name']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
    );
  }
}

class DriverOrderItem {
  final String name;
  final int quantity;
  final double amount;
  final double total;

  DriverOrderItem({
    required this.name,
    required this.quantity,
    required this.amount,
    required this.total,
  });

  factory DriverOrderItem.fromJson(Map<String, dynamic> json) {
    return DriverOrderItem(
      name: json['name']?.toString() ?? '',
      quantity:
          json['quantity'] is int
              ? json['quantity']
              : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DriverOrderDetailsModel {
  final bool success;
  final DriverOrderDetailsData data;

  DriverOrderDetailsModel({required this.success, required this.data});

  factory DriverOrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return DriverOrderDetailsModel(
      success: json['success'] == true,
      data: DriverOrderDetailsData.fromJson(json['data'] ?? {}),
    );
  }
}

class DriverOrderDetailsData {
  final int locationId;
  final DriverOrderDetailsOrder order;
  final DriverOrderCustomer customer;
  final DriverOrderLocation address;
  final List<DriverOrderItem> items;

  DriverOrderDetailsData({
    required this.locationId,
    required this.order,
    required this.customer,
    required this.address,
    required this.items,
  });

  factory DriverOrderDetailsData.fromJson(Map<String, dynamic> json) {
    return DriverOrderDetailsData(
      locationId: json['location_id'] ?? 0,
      order: DriverOrderDetailsOrder.fromJson(json['order'] ?? {}),
      customer: DriverOrderCustomer.fromJson(json['customer'] ?? {}),
      address: DriverOrderLocation.fromJson(json['address'] ?? {}),
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    DriverOrderItem.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class DriverOrderDetailsOrder {
  final double subTotal;
  final double delivery;
  final double total;
  final String paymentMode;
  final int preOrder;
  final String? preOrderDate;
  final String vehicleChoice;
  final String merchantOrderId;
  final String? deliveryNote;

  DriverOrderDetailsOrder({
    required this.subTotal,
    required this.delivery,
    required this.total,
    required this.paymentMode,
    required this.preOrder,
    this.preOrderDate,
    required this.vehicleChoice,
    required this.merchantOrderId,
    this.deliveryNote,
  });

  factory DriverOrderDetailsOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrderDetailsOrder(
      subTotal: (json['sub_total'] as num?)?.toDouble() ?? 0.0,
      delivery: (json['delivery'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode']?.toString() ?? '',
      preOrder:
          json['pre_order'] is int
              ? json['pre_order']
              : int.tryParse(json['pre_order']?.toString() ?? '0') ?? 0,
      preOrderDate: json['pre_order_date']?.toString(),
      vehicleChoice: json['vehicle_choice']?.toString() ?? '',
      merchantOrderId: json['merchant_order_id']?.toString() ?? '',
      deliveryNote: json['delivery_note']?.toString(),
    );
  }
}
