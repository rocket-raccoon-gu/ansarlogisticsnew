enum OrderItemStatus { toPick, picked, holded, canceled, itemNotAvailable }

class OrderItemModel {
  final String id;
  final String name;
  final String imageUrl;
  int quantity;
  OrderItemStatus status;
  final String? description;
  final String deliveryType;
  final String? sku;
  final double? price;
  final double? finalPrice; // Add final_price field for produce items
  final List<String> productImages;
  final String? isProduceRaw;
  final String? subgroupIdentifier;
  final String? deliveryNote; // Customer delivery note

  OrderItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.status,
    this.description,
    required this.deliveryType,
    this.sku,
    this.price,
    this.finalPrice,
    required this.productImages,
    this.isProduceRaw,
    this.subgroupIdentifier,
    this.deliveryNote,
  });

  bool get isProduce => isProduceRaw == '1';

  // Method to update item with new price and produce status
  OrderItemModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? quantity,
    OrderItemStatus? status,
    String? description,
    String? deliveryType,
    String? sku,
    double? price,
    double? finalPrice,
    List<String>? productImages,
    String? isProduceRaw,
    String? subgroupIdentifier,
    String? deliveryNote,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      description: description ?? this.description,
      deliveryType: deliveryType ?? this.deliveryType,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      finalPrice: finalPrice ?? this.finalPrice,
      productImages: productImages ?? this.productImages,
      isProduceRaw: isProduceRaw ?? this.isProduceRaw,
      subgroupIdentifier: subgroupIdentifier ?? this.subgroupIdentifier,
      deliveryNote: deliveryNote ?? this.deliveryNote,
    );
  }

  static int _parseQuantity(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        final doubleValue = double.tryParse(value);
        return doubleValue?.toInt() ?? 1;
      } catch (e) {
        return 1;
      }
    }
    return 1;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.tryParse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Parse product images
    List<String> images = [];
    if (json['product_images'] != null && json['product_images'] is String) {
      String imagesString = json['product_images'];
      if (imagesString.isNotEmpty) {
        images = imagesString.split(',').map((img) => img.trim()).toList();
      }
    }

    // Map API item_status to enum
    String apiStatus =
        (json['item_status'] ?? json['status'] ?? 'toPick').toString();
    OrderItemStatus status;
    switch (apiStatus) {
      case 'start_picking':
        status = OrderItemStatus.toPick;
        break;
      case 'end_picking':
        status = OrderItemStatus.picked;
        break;
      case 'item_not_available':
        status = OrderItemStatus.itemNotAvailable;
        break;
      case 'holded':
      case 'on_hold':
        status = OrderItemStatus.holded;
        break;
      case 'canceled':
        status = OrderItemStatus.canceled;
        break;
      default:
        status = OrderItemStatus.toPick;
    }

    return OrderItemModel(
      id: json['item_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      quantity: _parseQuantity(json['qty_ordered'] ?? json['quantity']),
      status: status,
      description: json['description'],
      deliveryType: json['delivery_type']?.toString() ?? '',
      sku: json['sku']?.toString(),
      price: _parseDouble(json['price']),
      finalPrice: _parseDouble(json['final_price']),
      productImages: images,
      isProduceRaw: json['is_produce']?.toString(),
      subgroupIdentifier: json['subgroup_identifier']?.toString(),
      deliveryNote: json['delivery_note']?.toString(),
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
      'sku': sku,
      'price': price,
      'final_price': finalPrice,
      'product_images': productImages.join(','),
      'subgroup_identifier': subgroupIdentifier,
      'delivery_note': deliveryNote,
    };
  }
}
