import 'order_item_model.dart';
import 'order_details_model.dart';

/// Example demonstrating how to use the subgroup_details functionality
/// in the OrderItemModel
class SubgroupDetailsExample {
  /// Example JSON data that would come from the API
  static Map<String, dynamic> getExampleApiResponse() {
    return {
      'item_id': '12345',
      'name': 'Sample Product',
      'image_url': 'https://example.com/image.jpg',
      'qty_ordered': 2,
      'item_status': 'start_picking',
      'description': 'A sample product for testing',
      'delivery_type': 'exp',
      'sku': 'SKU123',
      'price': 25.99,
      'final_price': 25.99,
      'product_images': 'image1.jpg,image2.jpg',
      'is_produce': '0',
      'subgroup_identifier': 'EXP-000092019',
      'delivery_note': 'Handle with care',
      'subgroup_details': [
        {
          'subgroup_identifier': 'NOL-000092019',
          'status': 'canceled_by_team',
          'delivery_date': '2025-07-20',
          'delivery_time': null,
        },
        {
          'subgroup_identifier': 'EXP-000092019',
          'status': 'start_picking',
          'delivery_date': '2025-07-19',
          'delivery_time': '12:00:00',
        },
      ],
    };
  }

  /// Example of how to create an OrderItemModel from API response
  static OrderItemModel createOrderItemFromApi() {
    final apiResponse = getExampleApiResponse();
    return OrderItemModel.fromJson(apiResponse);
  }

  /// Example of how to access subgroup status information
  static void demonstrateSubgroupStatusAccess() {
    final item = createOrderItemFromApi();

    print('Item: ${item.name}');
    print('Subgroup Details Count: ${item.subgroupDetails.length}');

    // Access specific status by identifier
    final expStatus = item.expStatus;
    final nolStatus = item.nolStatus;

    print('EXP Status: $expStatus');
    print('NOL Status: $nolStatus');

    // Access status using the general method
    final expStatusGeneral = item.getStatusBySubgroupIdentifier('EXP');
    final nolStatusGeneral = item.getStatusBySubgroupIdentifier('NOL');

    print('EXP Status (general method): $expStatusGeneral');
    print('NOL Status (general method): $nolStatusGeneral');

    // Access all subgroup details
    for (final detail in item.subgroupDetails) {
      print('Subgroup: ${detail.subgroupIdentifier}');
      print('  Status: ${detail.status}');
      print('  Delivery Date: ${detail.deliveryDate}');
      print('  Delivery Time: ${detail.deliveryTime}');
    }
  }

  /// Example of how to check if an item has specific subgroup status
  static bool isItemReadyForPicking(OrderItemModel item) {
    // Check if EXP subgroup is in start_picking status
    final expStatus = item.expStatus;
    return expStatus == 'start_picking';
  }

  /// Example of how to get items that are canceled
  static List<OrderItemModel> getCanceledItems(List<OrderItemModel> items) {
    return items.where((item) {
      final expStatus = item.expStatus;
      final nolStatus = item.nolStatus;
      return expStatus == 'canceled_by_team' || nolStatus == 'canceled_by_team';
    }).toList();
  }

  /// Example of how to update an item with new subgroup details
  static OrderItemModel updateItemWithNewSubgroupDetails(
    OrderItemModel item,
    List<SubgroupDetail> newSubgroupDetails,
  ) {
    return item.copyWith(subgroupDetails: newSubgroupDetails);
  }

  // Example of how TypeCardsWidget displays expStatus and nolStatus
  static void demonstrateTypeCardsWidgetUsage() {
    print('\n=== TypeCardsWidget Status Display Example ===');

    // Create example order item with subgroup statuses
    final orderItem = createOrderItemFromApi();

    // Simulate how the cubit would extract these statuses
    final expStatus = orderItem.expStatus;
    final nolStatus = orderItem.nolStatus;

    print('📊 Status Display in TypeCardsWidget:');
    print('  - EXP Status: ${expStatus ?? "No EXP items"}');
    print('  - NOL Status: ${nolStatus ?? "No NOL items"}');

    if (expStatus != null) {
      print(
        '  - EXP Card will show: "${expStatus.replaceAll('_', ' ').toUpperCase()}"',
      );
    }

    if (nolStatus != null) {
      print(
        '  - NOL Card will show: "${nolStatus.replaceAll('_', ' ').toUpperCase()}"',
      );
    }

    print('\n🎨 Visual Representation:');
    print(
      '  EXP Card: [🟠 Express Items] + [${expStatus != null ? _getStatusBadge(expStatus!) : "No Status"}]',
    );
    print(
      '  NOL Card: [🔵 Normal Local] + [${nolStatus != null ? _getStatusBadge(nolStatus!) : "No Status"}]',
    );
  }

  static String _getStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'start_picking':
        return '🔵 START PICKING';
      case 'end_picking':
        return '🟢 END PICKING';
      case 'canceled_by_team':
        return '🔴 CANCELED BY TEAM';
      default:
        return '⚪ ${status.replaceAll('_', ' ').toUpperCase()}';
    }
  }

  // Test function to debug the data flow issue
  static void debugDataFlowIssue() {
    print('\n=== Debugging Data Flow Issue ===');

    // Test 1: Check if OrderItemModel can parse subgroup_details
    final testItem = createOrderItemFromApi();
    print('✅ Test 1 - OrderItemModel parsing:');
    print('  - Item name: ${testItem.name}');
    print('  - Subgroup details count: ${testItem.subgroupDetails.length}');
    print('  - EXP Status: ${testItem.expStatus}');
    print('  - NOL Status: ${testItem.nolStatus}');

    // Test 2: Check if OrderDetailsModel can extract statuses
    final testApiResponse = {
      'preparation_label': 'TEST-001',
      'status': 'active',
      'created_at': '2025-01-01T00:00:00Z',
      'subgroup_identifier': 'TEST-001',
      'delivery_note': 'Test order',
      'items': [
        [
          'exp',
          [
            {
              'category': 'Test Category',
              'items': [
                {
                  'item_id': '12345',
                  'name': 'Test Product',
                  'delivery_type': 'exp',
                  'subgroup_details': [
                    {
                      'subgroup_identifier': 'EXP-000092019',
                      'status': 'start_picking',
                      'delivery_date': '2025-07-19',
                      'delivery_time': '12:00:00',
                    },
                  ],
                },
              ],
            },
          ],
        ],
        [
          'nol',
          [
            {
              'category': 'Test Category 2',
              'items': [
                {
                  'item_id': '67890',
                  'name': 'Test Product 2',
                  'delivery_type': 'nol',
                  'subgroup_details': [
                    {
                      'subgroup_identifier': 'NOL-000092019',
                      'status': 'canceled_by_team',
                      'delivery_date': '2025-07-20',
                      'delivery_time': null,
                    },
                  ],
                },
              ],
            },
          ],
        ],
      ],
    };

    try {
      //   final testOrderDetails = OrderDetailsModel.fromJson(testApiResponse);
      //   print('\n✅ Test 2 - OrderDetailsModel parsing:');
      //   print('  - Express items count: ${testOrderDetails.expressItems.length}');
      //   print('  - Normal items count: ${testOrderDetails.normalItems.length}');
      //   print('  - EXP Status: ${testOrderDetails.expStatus}');
      //   print('  - NOL Status: ${testOrderDetails.nolStatus}');

      //   if (testOrderDetails.expStatus != null) {
      //     print('  ✅ EXP Status found: ${testOrderDetails.expStatus}');
      //   } else {
      //     print('  ❌ EXP Status is null');
      //   }

      //   if (testOrderDetails.nolStatus != null) {
      //     print('  ✅ NOL Status found: ${testOrderDetails.nolStatus}');
      //   } else {
      //     print('  ❌ NOL Status is null');
      //   }
    } catch (e) {
      print('❌ Test 2 failed: $e');
    }

    // Test 3: Check if the issue might be with delivery_type filtering
    //   print('\n🔍 Test 3 - Potential Issues:');
    //   print('  1. Check if API response contains subgroup_details array');
    //   print('  2. Check if items have correct delivery_type values (exp/nol)');
    //   print('  3. Check if subgroup_identifier starts with EXP or NOL');
    //   print('  4. Check if the first item in each group has subgroup_details');
    // }
  }
}


/// Usage example in a real application:
/// 
/// ```dart
/// // In your API service or cubit
/// final apiResponse = await apiService.getOrderItemDetails(itemId);
/// final orderItem = OrderItemModel.fromJson(apiResponse);
/// 
/// // Check if item is ready for picking
/// if (orderItem.expStatus == 'start_picking') {
///   // Proceed with picking logic
///   await pickItem(orderItem);
/// }
/// 
/// // Check if item is canceled
/// if (orderItem.nolStatus == 'canceled_by_team') {
///   // Handle canceled item
///   showCanceledItemDialog(orderItem);
/// }
/// 
/// // Display subgroup details in UI
/// if (orderItem.subgroupDetails.isNotEmpty) {
///   // Show subgroup chips as implemented in order_item_details_page.dart
/// }
/// ``` 