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
  final List<String> productImages;
  final String? isProduceRaw;
  final String? subgroupIdentifier;

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
    this.isProduceRaw,
    this.subgroupIdentifier,
  });

  bool get isProduce => isProduceRaw == '1';

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
      isProduceRaw: json['is_produce']?.toString(),
      subgroupIdentifier: json['subgroup_identifier']?.toString(),
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
      'subgroup_identifier': subgroupIdentifier,
    };
  }
}
