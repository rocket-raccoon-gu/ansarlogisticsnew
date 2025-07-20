import 'order_item_model.dart';

class CategoryItemModel {
  final String category;
  final List<OrderItemModel> items;

  CategoryItemModel({required this.category, required this.items});

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems = [];

    if (json['items'] != null && json['items'] is List) {
      for (var itemJson in json['items']) {
        parsedItems.add(OrderItemModel.fromJson(itemJson));
      }
    }

    return CategoryItemModel(
      category: json['category'] ?? '',
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderDetailsModel {
  final int preparationId;
  final int? parentPreparationId;
  final String status;
  final DateTime createdAt;
  final String subgroupIdentifier;
  final List<CategoryItemModel> categories;

  OrderDetailsModel({
    required this.preparationId,
    this.parentPreparationId,
    required this.status,
    required this.createdAt,
    required this.subgroupIdentifier,
    required this.categories,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    List<CategoryItemModel> parsedCategories = [];

    print('Parsing OrderDetailsModel from JSON: ${json.keys}');
    print('Items structure: ${json['items']}');

    if (json['items'] != null && json['items'] is List) {
      for (var typeGroup in json['items']) {
        print('Processing typeGroup: $typeGroup');

        if (typeGroup is List && typeGroup.length >= 2) {
          final deliveryType = typeGroup[0]; // "exp" or "nol"
          final categories = typeGroup[1];

          print('Delivery type: $deliveryType');
          print('Categories: $categories');

          if (categories is List) {
            for (var categoryGroup in categories) {
              print('Processing categoryGroup: $categoryGroup');

              if (categoryGroup is Map) {
                try {
                  // The delivery_type is already provided by the API in each item
                  // No need to manually add it
                  if (categoryGroup['items'] is List) {
                    print(
                      'Found ${categoryGroup['items'].length} items in category ${categoryGroup['category']}',
                    );

                    // Debug: Print delivery types of items in this category
                    for (var itemJson in categoryGroup['items']) {
                      if (itemJson is Map) {
                        print(
                          'Item: ${itemJson['name']}, Delivery Type: ${itemJson['delivery_type']}',
                        );
                      }
                    }
                  }

                  parsedCategories.add(
                    CategoryItemModel.fromJson(
                      Map<String, dynamic>.from(categoryGroup),
                    ),
                  );
                } catch (e) {
                  print('Error parsing category group: $e');
                  print('Category group data: $categoryGroup');
                  // Continue with other categories even if one fails
                }
              }
            }
          } else {
            print('Categories is not a list: $categories');
          }
        } else {
          print('Invalid typeGroup structure: $typeGroup');
        }
      }
    }

    print('Total parsed categories: ${parsedCategories.length}');
    print(
      'Total items: ${parsedCategories.fold(0, (sum, cat) => sum + cat.items.length)}',
    );

    return OrderDetailsModel(
      preparationId: json['preparation_id'] ?? 0,
      parentPreparationId: json['parent_preparation_id'],
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      subgroupIdentifier: json['subgroup_identifier'] ?? '',
      categories: parsedCategories,
    );
  }

  // Helper method to get all items flattened
  List<OrderItemModel> get allItems {
    List<OrderItemModel> allItems = [];
    for (var category in categories) {
      allItems.addAll(category.items);
    }
    return allItems;
  }

  Map<String, dynamic> toJson() {
    return {
      'preparation_id': preparationId,
      'parent_preparation_id': parentPreparationId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'subgroup_identifier': subgroupIdentifier,
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }
}
