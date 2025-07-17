enum OrderItemStatus { toPick, picked, canceled, notAvailable }

class OrderItemModel {
  final String id;
  final String name;
  final String imageUrl;
  int quantity;
  OrderItemStatus status;
  final String? description;
  final String deliveryType;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.status,
    this.description,
    required this.deliveryType,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      quantity: json['quantity'] ?? 1,
      status: OrderItemStatus.values.firstWhere(
        (e) =>
            e.toString() == 'OrderItemStatus.' + (json['status'] ?? 'toPick'),
        orElse: () => OrderItemStatus.toPick,
      ),
      description: json['description'],
      deliveryType: json['delivery_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'quantity': quantity,
      'status': status.toString().split('.').last,
      'description': description,
      'delivery_type': deliveryType,
    };
  }
}
