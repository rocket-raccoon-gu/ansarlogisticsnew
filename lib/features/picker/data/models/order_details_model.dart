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

class DeliveryTypeGroup {
  final String deliveryType; // "exp" or "nol"
  final List<CategoryItemModel> categories;

  DeliveryTypeGroup({required this.deliveryType, required this.categories});

  // Get all items from all categories in this delivery type group
  List<OrderItemModel> get allItems {
    List<OrderItemModel> allItems = [];
    for (var category in categories) {
      allItems.addAll(category.items);
    }
    return allItems;
  }
}

class OrderDetailsModel {
  // final int preparationId;
  final String preparationLabel;
  // final int? parentPreparationId;
  final String status;
  final DateTime createdAt;
  final String subgroupIdentifier;
  final List<DeliveryTypeGroup> deliveryTypeGroups;
  final String? deliveryNote;
  final List<dynamic> subgroupDetails;
  final String? paymentMethod;

  OrderDetailsModel({
    // required this.preparationId,
    required this.preparationLabel,
    // this.parentPreparationId,
    required this.status,
    required this.createdAt,
    required this.subgroupIdentifier,
    required this.deliveryTypeGroups,
    this.deliveryNote,
    required this.subgroupDetails,
    this.paymentMethod,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    try {
      List<DeliveryTypeGroup> parsedDeliveryTypeGroups = [];

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

            List<CategoryItemModel> parsedCategories = [];

            if (categories is List) {
              for (var categoryGroup in categories) {
                print('Processing categoryGroup: $categoryGroup');

                if (categoryGroup is Map) {
                  try {
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

            // Create delivery type group
            parsedDeliveryTypeGroups.add(
              DeliveryTypeGroup(
                deliveryType: deliveryType,
                categories: parsedCategories,
              ),
            );
          } else {
            print('Invalid typeGroup structure: $typeGroup');
          }
        }
      }

      print(
        'Total parsed delivery type groups: ${parsedDeliveryTypeGroups.length}',
      );
      for (var group in parsedDeliveryTypeGroups) {
        print('${group.deliveryType}: ${group.allItems.length} items');
      }

      return OrderDetailsModel(
        // preparationId: _parsePreparationId(json['preparation_id']),
        preparationLabel: json['preparation_label'] ?? '',
        // parentPreparationId: json['parent_preparation_id'],
        status: json['status'] ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        subgroupIdentifier: json['subgroup_identifier'] ?? '',
        deliveryTypeGroups: parsedDeliveryTypeGroups,
        deliveryNote: json['delivery_note'] ?? '',
        subgroupDetails: json['subgroup_details'] ?? [],
        paymentMethod: json['payment_method'] ?? '',
      );
    } catch (e) {
      print('Error parsing OrderDetailsModel: $e');
      print('JSON data: $json');
      // Return a default model with empty data
      return OrderDetailsModel(
        // preparationId: 0,
        preparationLabel: '',
        status: '',
        createdAt: DateTime.now(),
        subgroupIdentifier: '',
        deliveryTypeGroups: [],
        deliveryNote: '',
        subgroupDetails: [],
        paymentMethod: '',
      );
    }
  }

  static int _parsePreparationId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Helper method to get all items flattened (for backward compatibility)
  List<OrderItemModel> get allItems {
    List<OrderItemModel> allItems = [];
    for (var group in deliveryTypeGroups) {
      allItems.addAll(group.allItems);
    }
    return allItems;
  }

  // Helper method to get all categories flattened (for backward compatibility)
  List<CategoryItemModel> get categories {
    List<CategoryItemModel> allCategories = [];
    for (var group in deliveryTypeGroups) {
      allCategories.addAll(group.categories);
    }
    return allCategories;
  }

  // Helper method to get express items
  List<OrderItemModel> get expressItems {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'exp') {
        return group.allItems;
      }
    }
    return [];
  }

  // Helper method to get normal items
  List<OrderItemModel> get normalItems {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'nol') {
        return group.allItems;
      }
    }
    return [];
  }

  // Helper method to get express categories
  List<CategoryItemModel> get expressCategories {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'exp') {
        return group.categories;
      }
    }
    return [];
  }

  // Helper method to get normal categories
  List<CategoryItemModel> get normalCategories {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'nol') {
        return group.categories;
      }
    }
    return [];
  }

  // Helper method to get warehouse items
  List<OrderItemModel> get warehouseItems {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'war') {
        return group.allItems;
      }
    }
    return [];
  }

  // Helper method to get warehouse categories
  List<CategoryItemModel> get warehouseCategories {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'war') {
        return group.categories;
      }
    }
    return [];
  }

  // Helper method to get supplier items
  List<OrderItemModel> get supplierItems {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'sup') {
        return group.allItems;
      }
    }
    return [];
  }

  // Helper method to get supplier categories
  List<CategoryItemModel> get supplierCategories {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'sup') {
        return group.categories;
      }
    }
    return [];
  }

  // Helper method to get vendor pickup items
  List<OrderItemModel> get vendorPickupItems {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'vpo') {
        return group.allItems;
      }
    }
    return [];
  }

  // Helper method to get vendor pickup categories
  List<CategoryItemModel> get vendorPickupCategories {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'vpo') {
        return group.categories;
      }
    }
    return [];
  }

  // Helper method to get abaya items
  List<OrderItemModel> get abayaItems {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'aby') {
        return group.allItems;
      }
    }
    return [];
  }

  // Helper method to get abaya categories
  List<CategoryItemModel> get abayaCategories {
    for (var group in deliveryTypeGroups) {
      if (group.deliveryType == 'aby') {
        return group.categories;
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      // 'preparation_id': preparationId,
      'preparation_label': preparationLabel,
      // 'parent_preparation_id': parentPreparationId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'subgroup_identifier': subgroupIdentifier,
      'delivery_type_groups':
          deliveryTypeGroups
              .map(
                (group) => {
                  'delivery_type': group.deliveryType,
                  'categories':
                      group.categories
                          .map((category) => category.toJson())
                          .toList(),
                },
              )
              .toList(),
      'delivery_note': deliveryNote,
      'subgroup_details': subgroupDetails,
      'payment_method': paymentMethod,
    };
  }
}
