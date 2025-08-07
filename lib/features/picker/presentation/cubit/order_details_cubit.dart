import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:api_gateway/services/api_service.dart';
import '../../data/models/order_details_model.dart';
import '../../data/models/order_item_model.dart';
import '../../../../core/services/user_storage_service.dart';

part 'order_details_state.dart';

class OrderDetailsCubit extends Cubit<OrderDetailsState> {
  final String orderId;
  final ApiService apiService;

  // Add a cache
  OrderDetailsModel? _cachedOrderDetails;

  OrderDetailsCubit({required this.orderId, required this.apiService})
    : super(OrderDetailsInitial());

  String? _cachedUsername;

  Future<void> loadItems() async {
    // If we have cached data, show it immediately
    final userData = await UserStorageService.getUserData();
    _cachedUsername = userData?.user?.name;

    if (_cachedOrderDetails != null) {
      final allItems = _cachedOrderDetails!.allItems;
      if (!isClosed) {
        print('🔍 OrderDetailsCubit - Using cached data:');
        print(
          '  - Cached EXP Status: ${_cachedOrderDetails!.subgroupDetails.firstWhere((item) => item['subgroup_identifier'].startsWith('EXP-'), orElse: () => null)['status']}',
        );
        print(
          '  - Cached NOL Status: ${_cachedOrderDetails!.subgroupDetails.firstWhere((item) => item['subgroup_identifier'].startsWith('NOL-'), orElse: () => null)['status']}',
        );

        emit(
          OrderDetailsLoaded(
            status: _cachedOrderDetails!.status,
            toPick:
                allItems
                    .where((item) => item.status == OrderItemStatus.toPick)
                    .toList(),
            picked:
                allItems
                    .where((item) => item.status == OrderItemStatus.picked)
                    .toList(),
            canceled:
                allItems
                    .where((item) => item.status == OrderItemStatus.canceled)
                    .toList(),
            notAvailable:
                allItems
                    .where(
                      (item) => item.status == OrderItemStatus.itemNotAvailable,
                    )
                    .toList(),
            holded:
                allItems
                    .where((item) => item.status == OrderItemStatus.holded)
                    .toList(),
            categories: _cachedOrderDetails!.categories,
            preparationLabel: _cachedOrderDetails!.preparationLabel,
            deliveryNote: _cachedOrderDetails!.deliveryNote,
            expressItems: _cachedOrderDetails!.expressItems,
            normalItems: _cachedOrderDetails!.normalItems,
            warehouseItems: _cachedOrderDetails!.warehouseItems,
            supplierItems: _cachedOrderDetails!.supplierItems,
            vendorPickupItems: _cachedOrderDetails!.vendorPickupItems,
            abayaItems: _cachedOrderDetails!.abayaItems,
            expressCategories: _cachedOrderDetails!.expressCategories,
            normalCategories: _cachedOrderDetails!.normalCategories,
            warehouseCategories: _cachedOrderDetails!.warehouseCategories,
            supplierCategories: _cachedOrderDetails!.supplierCategories,
            vendorPickupCategories: _cachedOrderDetails!.vendorPickupCategories,
            abayaCategories: _cachedOrderDetails!.abayaCategories,
            expStatus: _getExpStatus(_cachedOrderDetails!.subgroupDetails),
            nolStatus: _getNolStatus(_cachedOrderDetails!.subgroupDetails),
            warStatus: _getWarStatus(_cachedOrderDetails!.subgroupDetails),
            supStatus: _getSupStatus(_cachedOrderDetails!.subgroupDetails),
            vpoStatus: _getVpoStatus(_cachedOrderDetails!.subgroupDetails),
            abyStatus: _getAbyStatus(_cachedOrderDetails!.subgroupDetails),
            paymentMethod: _cachedOrderDetails!.paymentMethod,
            expTotal: _getExTotal(_cachedOrderDetails!.subgroupDetails),
            nolTotal: _getNolTotal(_cachedOrderDetails!.subgroupDetails),
            warTotal: _getWarTotal(_cachedOrderDetails!.subgroupDetails),
            supTotal: _getSupTotal(_cachedOrderDetails!.subgroupDetails),
            vpoTotal: _getVpoTotal(_cachedOrderDetails!.subgroupDetails),
            abyTotal: _getAbyTotal(_cachedOrderDetails!.subgroupDetails),
            username: _cachedUsername,
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(OrderDetailsLoading(preparationId: _parseOrderId(orderId)));
      }
    }

    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!isClosed) {
          emit(OrderDetailsError('No authentication token found'));
        }
        return;
      }

      final response = await apiService.fetchPickerOrderDetails(orderId, token);

      if (response != null) {
        final orderDetails = OrderDetailsModel.fromJson(response);
        _cachedOrderDetails = orderDetails; // cache it

        final allItems = orderDetails.allItems;

        // Categorize items by status
        final toPick =
            allItems
                .where((item) => item.status == OrderItemStatus.toPick)
                .toList();
        final picked =
            allItems
                .where((item) => item.status == OrderItemStatus.picked)
                .toList();
        final canceled =
            allItems
                .where((item) => item.status == OrderItemStatus.canceled)
                .toList();
        final notAvailable =
            allItems
                .where(
                  (item) => item.status == OrderItemStatus.itemNotAvailable,
                )
                .toList();
        final holded =
            allItems
                .where((item) => item.status == OrderItemStatus.holded)
                .toList();

        if (!isClosed) {
          emit(
            OrderDetailsLoaded(
              status: _cachedOrderDetails!.status,
              toPick: toPick,
              picked: picked,
              canceled: canceled,
              holded: holded,
              notAvailable: notAvailable,
              categories: orderDetails.categories,
              preparationLabel: orderDetails.preparationLabel,
              deliveryNote: orderDetails.deliveryNote,
              expressItems: orderDetails.expressItems,
              normalItems: orderDetails.normalItems,
              warehouseItems: orderDetails.warehouseItems,
              supplierItems: orderDetails.supplierItems,
              vendorPickupItems: orderDetails.vendorPickupItems,
              abayaItems: orderDetails.abayaItems,
              expressCategories: orderDetails.expressCategories,
              normalCategories: orderDetails.normalCategories,
              warehouseCategories: orderDetails.warehouseCategories,
              supplierCategories: orderDetails.supplierCategories,
              vendorPickupCategories: orderDetails.vendorPickupCategories,
              abayaCategories: orderDetails.abayaCategories,
              expStatus: _getExpStatus(orderDetails.subgroupDetails),
              nolStatus: _getNolStatus(orderDetails.subgroupDetails),
              warStatus: _getWarStatus(orderDetails.subgroupDetails),
              supStatus: _getSupStatus(orderDetails.subgroupDetails),
              vpoStatus: _getVpoStatus(orderDetails.subgroupDetails),
              abyStatus: _getAbyStatus(orderDetails.subgroupDetails),
              paymentMethod: orderDetails.paymentMethod,
              expTotal: _getExTotal(orderDetails.subgroupDetails),
              nolTotal: _getNolTotal(orderDetails.subgroupDetails),
              warTotal: _getWarTotal(orderDetails.subgroupDetails),
              supTotal: _getSupTotal(orderDetails.subgroupDetails),
              vpoTotal: _getVpoTotal(orderDetails.subgroupDetails),
              abyTotal: _getAbyTotal(orderDetails.subgroupDetails),
              username: _cachedUsername,
            ),
          );
        }

        // Debug logging for cubit state
        print('🔍 OrderDetailsCubit - State populated:');
        print('  - Express items: ${orderDetails.expressItems.length}');
        print('  - Normal items: ${orderDetails.normalItems.length}');
        print(
          '  - Express picked: ${orderDetails.expressItems.where((item) => item.status == OrderItemStatus.picked).length}',
        );
        print(
          '  - Normal picked: ${orderDetails.normalItems.where((item) => item.status == OrderItemStatus.picked).length}',
        );
        print('  - Total picked: ${picked.length}');
        print('  - Total toPick: ${toPick.length}');
        // print('  - EXP Status: ${orderDetails.expStatus}');
        // print('  - NOL Status: ${orderDetails.nolStatus}');
      } else {
        if (!isClosed) {
          emit(OrderDetailsError('No data received from server'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        log('🔍 OrderDetailsCubit - Error: $e');
        emit(OrderDetailsError(e.toString()));
      }
    }
  }

  Future<bool> updateItemStatus({
    required OrderItemModel item,
    required String status,
    required String scannedSku,
    required int quantity,
    String? reason,
    String? priceOverride,
    required int isProduceOverride,
  }) async {
    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!isClosed) {
          emit(OrderDetailsError('No authentication token found'));
        }
        return false;
      }

      final response = await apiService.updateItemStatus(
        itemId: int.parse(item.id),
        scannedSku: scannedSku,
        status: status,
        price: priceOverride ?? (item.price ?? 0.0).toString(),
        qty: quantity.toString(),
        preparationId: orderId,
        isProduce: isProduceOverride,
        reason: reason,
        token: token,
        orderNumber: item.subgroupIdentifier ?? '',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local item status based on API response
        switch (status) {
          case 'end_picking':
            item.status = OrderItemStatus.picked;
            break;
          case 'item_not_available':
            item.status = OrderItemStatus.itemNotAvailable;
            break;
          case 'item_canceled':
            item.status = OrderItemStatus.canceled;
            break;
          case 'holded':
            item.status = OrderItemStatus.holded;
            break;
          case 'canceled':
            item.status = OrderItemStatus.canceled;
            break;
        }

        // Create updated item with new status and quantity
        final updatedItem = item.copyWith(
          status: item.status,
          quantity:
              quantity, // Update the quantity to match what was sent to API
          price:
              priceOverride != null
                  ? double.tryParse(priceOverride)
                  : item.price,
          finalPrice:
              priceOverride != null
                  ? double.tryParse(priceOverride)
                  : item.finalPrice,
          isProduceRaw:
              isProduceOverride != null
                  ? isProduceOverride.toString()
                  : item.isProduceRaw,
        );

        // Replace the item in all lists
        _updateItemInLists(item, updatedItem);

        print(
          '✅ Item updated: ${item.name} - Status: ${updatedItem.status}, Quantity: ${updatedItem.quantity}, Price: ${updatedItem.price}, Final Price: ${updatedItem.finalPrice}, IsProduce: ${updatedItem.isProduce}',
        );

        updateState();
        return true;
      } else {
        if (!isClosed) {
          emit(OrderDetailsError('Failed to update item status'));
        }
        return false;
      }
    } catch (e) {
      if (!isClosed) {
        emit(OrderDetailsError(e.toString()));
      }
      return false;
    }
  }

  void markPicked(OrderItemModel item) {
    // Create updated item with new status
    final updatedItem = item.copyWith(status: OrderItemStatus.picked);
    _updateItemInLists(item, updatedItem);
    updateState();
  }

  void markOutOfStock(OrderItemModel item) {
    // Create updated item with new status
    final updatedItem = item.copyWith(status: OrderItemStatus.itemNotAvailable);
    _updateItemInLists(item, updatedItem);
    updateState();
  }

  void markCanceled(OrderItemModel item) {
    // Create updated item with new status
    final updatedItem = item.copyWith(status: OrderItemStatus.canceled);
    _updateItemInLists(item, updatedItem);
    updateState();
  }

  void updateQuantity(OrderItemModel item, int newQuantity) {
    // Create updated item with new quantity
    final updatedItem = item.copyWith(quantity: newQuantity);
    _updateItemInLists(item, updatedItem);
    updateState();
  }

  void updateItemStatusByBarcode({
    String? notAvailableBarcode,
    String? pickedBarcode,
  }) {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      for (final item in [
        ...currentState.toPick,
        ...currentState.picked,
        ...currentState.canceled,
        ...currentState.notAvailable,
      ]) {
        if (notAvailableBarcode != null && item.sku == notAvailableBarcode) {
          final updatedItem = item.copyWith(
            status: OrderItemStatus.itemNotAvailable,
          );
          _updateItemInLists(item, updatedItem);
        }
        if (pickedBarcode != null && item.sku == pickedBarcode) {
          final updatedItem = item.copyWith(status: OrderItemStatus.picked);
          _updateItemInLists(item, updatedItem);
        }
      }
      updateState();
    }
  }

  // Helper method to update an item in all lists
  void _updateItemInLists(OrderItemModel oldItem, OrderItemModel newItem) {
    // Update the cached order details first
    if (_cachedOrderDetails != null) {
      // Create new delivery type groups with updated items
      List<DeliveryTypeGroup> updatedDeliveryTypeGroups = [];

      for (var group in _cachedOrderDetails!.deliveryTypeGroups) {
        List<CategoryItemModel> updatedCategories = [];

        for (var category in group.categories) {
          List<OrderItemModel> updatedItems = [];

          for (var item in category.items) {
            if (item.id == oldItem.id) {
              updatedItems.add(newItem);
              print(
                '🔍 OrderDetailsCubit - Updated item in category ${category.category}: ${newItem.name} -> Status: ${newItem.status}',
              );
            } else {
              updatedItems.add(item);
            }
          }

          updatedCategories.add(
            CategoryItemModel(category: category.category, items: updatedItems),
          );
        }

        updatedDeliveryTypeGroups.add(
          DeliveryTypeGroup(
            deliveryType: group.deliveryType,
            categories: updatedCategories,
          ),
        );
      }

      // Update the cached order details with new delivery type groups
      _cachedOrderDetails = OrderDetailsModel(
        preparationLabel: _cachedOrderDetails!.preparationLabel,
        status: _cachedOrderDetails!.status,
        createdAt: _cachedOrderDetails!.createdAt,
        subgroupIdentifier: _cachedOrderDetails!.subgroupIdentifier,
        deliveryTypeGroups: updatedDeliveryTypeGroups,
        deliveryNote: _cachedOrderDetails!.deliveryNote,
        subgroupDetails: _cachedOrderDetails!.subgroupDetails,
      );

      print(
        '🔍 OrderDetailsCubit - Updated cached order details with new item: ${newItem.name} -> Status: ${newItem.status}',
      );
    }

    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      // Update item in toPick list
      final toPickIndex = currentState.toPick.indexWhere(
        (item) => item.id == oldItem.id,
      );
      if (toPickIndex != -1) {
        currentState.toPick[toPickIndex] = newItem;
      }

      // Update item in picked list
      final pickedIndex = currentState.picked.indexWhere(
        (item) => item.id == oldItem.id,
      );
      if (pickedIndex != -1) {
        currentState.picked[pickedIndex] = newItem;
      }

      // Update item in canceled list
      final canceledIndex = currentState.canceled.indexWhere(
        (item) => item.id == oldItem.id,
      );
      if (canceledIndex != -1) {
        currentState.canceled[canceledIndex] = newItem;
      }

      // Update item in notAvailable list
      final notAvailableIndex = currentState.notAvailable.indexWhere(
        (item) => item.id == oldItem.id,
      );
      if (notAvailableIndex != -1) {
        currentState.notAvailable[notAvailableIndex] = newItem;
      }

      // Update item in categories
      for (final category in currentState.categories) {
        final categoryItemIndex = category.items.indexWhere(
          (item) => item.id == oldItem.id,
        );
        if (categoryItemIndex != -1) {
          category.items[categoryItemIndex] = newItem;
        }
      }

      // Emit updated state
      if (!isClosed) {
        emit(
          OrderDetailsLoaded(
            status: _cachedOrderDetails!.status,
            toPick: currentState.toPick,
            picked: currentState.picked,
            canceled: currentState.canceled,
            notAvailable: currentState.notAvailable,
            categories: currentState.categories,
            preparationLabel: currentState.preparationLabel,
            deliveryNote: currentState.deliveryNote,
            expressItems: currentState.expressItems,
            normalItems: currentState.normalItems,
            warehouseItems: currentState.warehouseItems,
            supplierItems: currentState.supplierItems,
            vendorPickupItems: currentState.vendorPickupItems,
            abayaItems: currentState.abayaItems,
            expressCategories: currentState.expressCategories,
            normalCategories: currentState.normalCategories,
            warehouseCategories: currentState.warehouseCategories,
            supplierCategories: currentState.supplierCategories,
            vendorPickupCategories: currentState.vendorPickupCategories,
            abayaCategories: currentState.abayaCategories,
            expStatus: currentState.expStatus,
            nolStatus: currentState.nolStatus,
            warStatus: currentState.warStatus,
            supStatus: currentState.supStatus,
            vpoStatus: currentState.vpoStatus,
            abyStatus: currentState.abyStatus,
            paymentMethod: currentState.paymentMethod,
            holded: currentState.holded,
            expTotal: currentState.expTotal,
            nolTotal: currentState.nolTotal,
            warTotal: currentState.warTotal,
            supTotal: currentState.supTotal,
            vpoTotal: currentState.vpoTotal,
            abyTotal: currentState.abyTotal,
          ),
        );
      }
    }
  }

  void updateState() {
    print('🔍 OrderDetailsCubit - updateState() called');
    final currentState = state;
    if (currentState is OrderDetailsLoaded && _cachedOrderDetails != null) {
      // Use cached order details to get the current state of all items
      final allItems = _cachedOrderDetails!.allItems;

      // Debug logging for updateState
      print('🔍 OrderDetailsCubit - updateState called:');
      print('  - Total items in cache: ${allItems.length}');
      print('  - Items by status:');
      for (var item in allItems) {
        print('    - ${item.name}: ${item.status} (ID: ${item.id})');
      }

      // Re-categorize items based on their current status
      final toPick =
          allItems
              .where((item) => item.status == OrderItemStatus.toPick)
              .toList();
      final picked =
          allItems
              .where((item) => item.status == OrderItemStatus.picked)
              .toList();
      final canceled =
          allItems
              .where((item) => item.status == OrderItemStatus.canceled)
              .toList();
      final notAvailable =
          allItems
              .where((item) => item.status == OrderItemStatus.itemNotAvailable)
              .toList();
      final holded =
          allItems
              .where((item) => item.status == OrderItemStatus.holded)
              .toList();

      print('🔍 OrderDetailsCubit - Re-categorized items:');
      print('  - toPick: ${toPick.length}');
      print('  - picked: ${picked.length}');
      print('  - canceled: ${canceled.length}');
      print('  - notAvailable: ${notAvailable.length}');

      if (!isClosed) {
        emit(
          OrderDetailsLoaded(
            status: _cachedOrderDetails!.status,
            toPick: toPick,
            picked: picked,
            canceled: canceled,
            notAvailable: notAvailable,
            holded: holded,
            categories: _cachedOrderDetails!.categories,
            preparationLabel: _cachedOrderDetails!.preparationLabel,
            deliveryNote: _cachedOrderDetails!.deliveryNote,
            expressItems: _cachedOrderDetails!.expressItems,
            normalItems: _cachedOrderDetails!.normalItems,
            warehouseItems: _cachedOrderDetails!.warehouseItems,
            supplierItems: _cachedOrderDetails!.supplierItems,
            vendorPickupItems: _cachedOrderDetails!.vendorPickupItems,
            abayaItems: _cachedOrderDetails!.abayaItems,
            expressCategories: _cachedOrderDetails!.expressCategories,
            normalCategories: _cachedOrderDetails!.normalCategories,
            warehouseCategories: _cachedOrderDetails!.warehouseCategories,
            supplierCategories: _cachedOrderDetails!.supplierCategories,
            vendorPickupCategories: _cachedOrderDetails!.vendorPickupCategories,
            abayaCategories: _cachedOrderDetails!.abayaCategories,
            expStatus: _getExpStatus(_cachedOrderDetails!.subgroupDetails),
            nolStatus: _getNolStatus(_cachedOrderDetails!.subgroupDetails),
            warStatus: _getWarStatus(_cachedOrderDetails!.subgroupDetails),
            supStatus: _getSupStatus(_cachedOrderDetails!.subgroupDetails),
            vpoStatus: _getVpoStatus(_cachedOrderDetails!.subgroupDetails),
            abyStatus: _getAbyStatus(_cachedOrderDetails!.subgroupDetails),
            paymentMethod: _cachedOrderDetails!.paymentMethod,
            expTotal: _getExTotal(_cachedOrderDetails!.subgroupDetails),
            nolTotal: _getNolTotal(_cachedOrderDetails!.subgroupDetails),
            warTotal: _getWarTotal(_cachedOrderDetails!.subgroupDetails),
            supTotal: _getSupTotal(_cachedOrderDetails!.subgroupDetails),
            vpoTotal: _getVpoTotal(_cachedOrderDetails!.subgroupDetails),
            abyTotal: _getAbyTotal(_cachedOrderDetails!.subgroupDetails),
            username: _cachedUsername,
          ),
        );
        print('🔍 OrderDetailsCubit - New state emitted');
      }
    } else {
      print(
        '🔍 OrderDetailsCubit - updateState: No cached order details or invalid state',
      );
    }
  }

  Future<void> reloadItemsFromApi() async {
    _cachedOrderDetails = null;
    await loadItems();
  }

  Future<void> cancelOrder({
    required String orderNumber,
    String? cancelReason,
  }) async {
    try {
      print('🔍 Canceling order with reason: $cancelReason');

      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!isClosed) {
          emit(OrderDetailsError('No authentication token found'));
        }
        return;
      }

      final response = await apiService.updateOrderStatus(
        'cancel_request',
        orderId,
        token,
        orderNumber: orderNumber,
        cancelReason: cancelReason,
      );

      print('🔍 Cancel order API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Don't emit error state for successful cancellation
        // Just print success message
        print('✅ Order canceled successfully');
      } else {
        if (!isClosed) {
          emit(OrderDetailsError('Failed to cancel order'));
        }
      }
    } catch (e) {
      print('❌ Error canceling order: $e');
      if (!isClosed) {
        emit(OrderDetailsError(e.toString()));
      }
    }
  }

  Future<void> endPicking({required String orderNumber}) async {
    try {
      print('🔍 endPicking - orderId: $orderId');
      print('🔍 endPicking - orderNumber: $orderNumber');

      if (orderId.isEmpty) {
        print('❌ endPicking - orderId is empty');
        if (!isClosed) {
          emit(OrderDetailsError('Order ID is missing'));
        }
        return;
      }

      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!isClosed) {
          emit(OrderDetailsError('No authentication token found'));
        }
        return;
      }

      final response = await apiService.updateOrderStatus(
        'end_picking',
        orderId,
        token,
        orderNumber: orderNumber,
      );

      if (response.statusCode == 200) {
        // Don't emit error state for successful end picking
        // Just print success message
        print('✅ Picking ended successfully');
      } else {
        if (!isClosed) {
          emit(OrderDetailsError('Failed to end picking'));
        }
      }
    } catch (e) {
      print('❌ endPicking error: $e');
      if (!isClosed) {
        emit(OrderDetailsError(e.toString()));
      }
    }
  }

  Future<void> updateOrderStatus({
    required String status,
    String? reason,
  }) async {
    try {
      print('🔍 Updating order status to: $status with reason: $reason');

      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!isClosed) {
          emit(OrderDetailsError('No authentication token found'));
        }
        return;
      }

      final response = await apiService.updateOrderStatus(
        status,
        orderId,
        token,
        orderNumber: '',
        cancelReason: reason,
      );

      print('🔍 Update order status API response: ${response.statusCode}');

      log('🔍 Update order status API response: ${response.body}');

      if (response.statusCode == 200) {
        // Don't emit error state for successful status update
        // Just print success message
        print('✅ Order status updated successfully');
      } else {
        if (!isClosed) {
          emit(OrderDetailsError('Failed to update order status'));
        }
      }
    } catch (e) {
      print('❌ Error updating order status: $e');
      if (!isClosed) {
        emit(OrderDetailsError(e.toString()));
      }
    }
  }

  int _parseOrderId(String orderId) {
    try {
      return int.parse(orderId);
    } catch (e) {
      // Fallback to 0 if parsing fails
      return 0;
    }
  }

  // Helper method to safely get EXP status
  String? _getExpStatus(List<dynamic> subgroupDetails) {
    try {
      final expItem = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('EXP-'),
        orElse: () => <String, dynamic>{},
      );
      return expItem.isNotEmpty
          ? (expItem as Map<String, dynamic>)['status']
          : null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to safely get NOL status
  String? _getNolStatus(List<dynamic> subgroupDetails) {
    try {
      final nolItem = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('NOL-'),
        orElse: () => <String, dynamic>{},
      );
      return nolItem.isNotEmpty
          ? (nolItem as Map<String, dynamic>)['status']
          : null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to safely get WAR status
  String? _getWarStatus(List<dynamic> subgroupDetails) {
    try {
      final warItem = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('WAR-'),
        orElse: () => <String, dynamic>{},
      );
      return warItem.isNotEmpty
          ? (warItem as Map<String, dynamic>)['status']
          : null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to safely get SUP status
  String? _getSupStatus(List<dynamic> subgroupDetails) {
    try {
      final supItem = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('SUP-'),
        orElse: () => <String, dynamic>{},
      );
      return supItem.isNotEmpty
          ? (supItem as Map<String, dynamic>)['status']
          : null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to safely get VPO status
  String? _getVpoStatus(List<dynamic> subgroupDetails) {
    try {
      final vpoItem = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('VPO-'),
        orElse: () => <String, dynamic>{},
      );
      return vpoItem.isNotEmpty
          ? (vpoItem as Map<String, dynamic>)['status']
          : null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to safely get ABY status
  String? _getAbyStatus(List<dynamic> subgroupDetails) {
    try {
      final abyItem = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('ABY-'),
        orElse: () => <String, dynamic>{},
      );
      return abyItem.isNotEmpty
          ? (abyItem as Map<String, dynamic>)['status']
          : null;
    } catch (e) {
      return null;
    }
  }

  String? _getExTotal(List<dynamic> subgroupDetails) {
    try {
      final exTotal = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('EXP-'),
      );
      return exTotal.isNotEmpty
          ? (exTotal as Map<String, dynamic>)['order_amount'].toString()
          : null;
    } catch (e) {
      return null;
    }
  }

  String? _getNolTotal(List<dynamic> subgroupDetails) {
    try {
      final nolTotal = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('NOL-'),
      );
      return nolTotal.isNotEmpty
          ? (nolTotal as Map<String, dynamic>)['order_amount'].toString()
          : null;
    } catch (e) {
      return null;
    }
  }

  String? _getWarTotal(List<dynamic> subgroupDetails) {
    try {
      final warTotal = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('WAR-'),
      );
      return warTotal.isNotEmpty
          ? (warTotal as Map<String, dynamic>)['order_amount'].toString()
          : null;
    } catch (e) {
      return null;
    }
  }

  String? _getSupTotal(List<dynamic> subgroupDetails) {
    try {
      final supTotal = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('SUP-'),
      );
      return supTotal.isNotEmpty
          ? (supTotal as Map<String, dynamic>)['order_amount'].toString()
          : null;
    } catch (e) {
      return null;
    }
  }

  String? _getVpoTotal(List<dynamic> subgroupDetails) {
    try {
      final vpoTotal = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('VPO-'),
      );
      return vpoTotal.isNotEmpty
          ? (vpoTotal as Map<String, dynamic>)['order_amount'].toString()
          : null;
    } catch (e) {
      return null;
    }
  }

  String? _getAbyTotal(List<dynamic> subgroupDetails) {
    try {
      final abyTotal = subgroupDetails.firstWhere(
        (item) => (item as Map<String, dynamic>)['subgroup_identifier']
            .startsWith('ABY-'),
      );
      return abyTotal.isNotEmpty
          ? (abyTotal as Map<String, dynamic>)['order_amount'].toString()
          : null;
    } catch (e) {
      return null;
    }
  }
}
