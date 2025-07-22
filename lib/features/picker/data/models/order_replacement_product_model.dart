class OrderReplacementProductModel {
  final int productId;
  final String sku;
  final String skuName;
  final String productType;
  final String regularPrice;
  final String? specialPrice;
  final String? erpCurrentPrice;
  final String deliveryType;
  final String isProduce;
  final String? images;
  final String? barcodes;
  final String currentPromotionPrice;
  final int priority;
  final String match;

  OrderReplacementProductModel({
    required this.productId,
    required this.sku,
    required this.skuName,
    required this.productType,
    required this.regularPrice,
    this.specialPrice,
    this.erpCurrentPrice,
    required this.deliveryType,
    required this.isProduce,
    this.images,
    this.barcodes,
    required this.currentPromotionPrice,
    required this.priority,
    required this.match,
  });

  factory OrderReplacementProductModel.fromJson(Map<String, dynamic> json) {
    return OrderReplacementProductModel(
      productId: json['product_id'] as int,
      sku: json['sku'] as String,
      skuName: json['sku_name'] as String,
      productType: json['product_type'] as String,
      regularPrice: json['regular_price'] as String,
      specialPrice: json['special_price'] as String?,
      erpCurrentPrice: json['erp_current_price'] as String?,
      deliveryType: json['delivery_type'] as String,
      isProduce: json['is_produce'] as String,
      images: json['images'] as String?,
      barcodes: json['barcodes'] as String?,
      currentPromotionPrice: json['current_promotion_price'] as String,
      priority:
          json['priority'] is int
              ? json['priority'] as int
              : int.tryParse(json['priority'].toString()) ?? 0,
      match: json['match'] as String,
    );
  }

  String? get firstImageUrl {
    if (images == null || images!.isEmpty) return null;
    final parts = images!.split(',');
    return parts.isNotEmpty ? parts.first : null;
  }
}
