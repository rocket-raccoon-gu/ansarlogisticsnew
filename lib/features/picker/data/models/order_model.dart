import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_item_model.dart';

class OrderModel {
  final String preparationId;
  final int itemCount;
  final String branchCode;
  final int customerId;
  final String customerFirstname;
  final String? customerLastname;
  final String customerEmail;
  final String customerZone;
  final String phone;
  final String status;
  final DateTime createdAt;
  final DateTime deliveryFrom;
  final DateTime? deliveryTo;
  final String? timerange;
  final int pickerId;
  final int? driverId;
  final List<OrderItemModel> items;

  OrderModel({
    required this.preparationId,
    required this.itemCount,
    required this.branchCode,
    required this.customerId,
    required this.customerFirstname,
    this.customerLastname,
    required this.customerEmail,
    required this.customerZone,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.deliveryFrom,
    this.deliveryTo,
    this.timerange,
    required this.pickerId,
    this.driverId,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items from nested structure
    List<OrderItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      for (var typeGroup in json['items']) {
        if (typeGroup is List && typeGroup.length == 2) {
          final type = typeGroup[0]; // "exp" or "nol"
          final categories = typeGroup[1];
          if (categories is List) {
            for (var categoryGroup in categories) {
              if (categoryGroup is Map && categoryGroup['items'] is List) {
                for (var itemJson in categoryGroup['items']) {
                  // Add the delivery type to each item
                  itemJson['delivery_type'] = type;
                  parsedItems.add(OrderItemModel.fromJson(itemJson));
                }
              }
            }
          }
        }
      }
    }
    return OrderModel(
      preparationId: json['preparation_id']?.toString() ?? '',
      itemCount:
          json['item_count'] is int
              ? json['item_count']
              : int.tryParse(json['item_count']?.toString() ?? '0') ?? 0,
      branchCode: json['branch_code']?.toString() ?? '',
      customerId:
          json['customer_id'] is int
              ? json['customer_id']
              : int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      customerFirstname: json['customer_firstname']?.toString() ?? '',
      customerLastname: json['customer_lastname']?.toString(),
      customerEmail: json['customer_email']?.toString() ?? '',
      customerZone: json['customer_zone']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      deliveryFrom:
          DateTime.tryParse(json['delivery_from']?.toString() ?? '') ??
          DateTime.now(),
      deliveryTo:
          json['delivery_to'] != null
              ? DateTime.tryParse(json['delivery_to'].toString())
              : null,
      timerange: json['timerange']?.toString(),
      pickerId:
          json['picker_id'] is int
              ? json['picker_id']
              : int.tryParse(json['picker_id']?.toString() ?? '0') ?? 0,
      driverId:
          json['driver_id'] != null
              ? (json['driver_id'] is int
                  ? json['driver_id']
                  : int.tryParse(json['driver_id'].toString()))
              : null,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preparation_id': preparationId,
      'item_count': itemCount,
      'branch_code': branchCode,
      'customer_id': customerId,
      'customer_firstname': customerFirstname,
      'customer_lastname': customerLastname,
      'customer_email': customerEmail,
      'customer_zone': customerZone,
      'phone': phone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'delivery_from': deliveryFrom.toIso8601String(),
      'delivery_to': deliveryTo?.toIso8601String(),
      'timerange': timerange,
      'picker_id': pickerId,
      'driver_id': driverId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
