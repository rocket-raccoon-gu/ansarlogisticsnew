enum OrderItemStatus { toPick, picked, canceled, notAvailable }

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
  final List<String> productImages;

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
    required this.productImages,
  });

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
        status = OrderItemStatus.notAvailable;
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
      quantity:
          json['qty_ordered'] != null
              ? double.tryParse(json['qty_ordered'].toString())?.toInt() ?? 1
              : json['quantity'] ?? 1,
      status: status,
      description: json['description'],
      deliveryType: json['delivery_type']?.toString() ?? '',
      sku: json['sku']?.toString(),
      price:
          json['price'] != null
              ? double.tryParse(json['price'].toString())
              : null,
      productImages: images,
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
      'product_images': productImages.join(','),
    };
  }
}
