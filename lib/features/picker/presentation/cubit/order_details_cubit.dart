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

  Future<void> loadItems() async {
    // If we have cached data, show it immediately
    if (_cachedOrderDetails != null) {
      final allItems = _cachedOrderDetails!.allItems;
      emit(
        OrderDetailsLoaded(
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
          categories: _cachedOrderDetails!.categories,
          preparationLabel: _cachedOrderDetails!.preparationLabel,
          deliveryNote: _cachedOrderDetails!.deliveryNote,
          expressItems: _cachedOrderDetails!.expressItems,
          normalItems: _cachedOrderDetails!.normalItems,
          expressCategories: _cachedOrderDetails!.expressCategories,
          normalCategories: _cachedOrderDetails!.normalCategories,
        ),
      );
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

        if (!isClosed) {
          emit(
            OrderDetailsLoaded(
              toPick: toPick,
              picked: picked,
              canceled: canceled,
              notAvailable: notAvailable,
              categories: orderDetails.categories,
              preparationLabel: orderDetails.preparationLabel,
              deliveryNote: orderDetails.deliveryNote,
              expressItems: orderDetails.expressItems,
              normalItems: orderDetails.normalItems,
              expressCategories: orderDetails.expressCategories,
              normalCategories: orderDetails.normalCategories,
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
      } else {
        if (!isClosed) {
          emit(OrderDetailsError('No data received from server'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(OrderDetailsError(e.toString()));
      }
    }
  }

  Future<bool> updateItemStatus({
    required OrderItemModel item,
    required String status,
    required String scannedSku,
    String? reason,
    String? priceOverride,
    int? isProduceOverride,
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
        qty: item.quantity.toString(),
        preparationId: int.parse(orderId),
        isProduce: isProduceOverride ?? (item.isProduce ? 1 : 0),
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
        }

        // Update item price and produce status if provided
        if (priceOverride != null || isProduceOverride != null) {
          final newPrice =
              priceOverride != null ? double.tryParse(priceOverride) : null;
          final newIsProduceRaw =
              isProduceOverride != null ? isProduceOverride.toString() : null;

          // Create updated item with new values
          final updatedItem = item.copyWith(
            price: newPrice,
            finalPrice:
                newPrice, // Set final_price to the same value for produce items
            isProduceRaw: newIsProduceRaw,
          );

          // Replace the item in all lists
          _updateItemInLists(item, updatedItem);

          print(
            '✅ Item updated: ${item.name} - Price: ${updatedItem.price}, Final Price: ${updatedItem.finalPrice}, IsProduce: ${updatedItem.isProduce}',
          );
        }

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
    item.status = OrderItemStatus.picked;
    updateState();
  }

  void markOutOfStock(OrderItemModel item) {
    item.status = OrderItemStatus.itemNotAvailable;
    updateState();
  }

  void markCanceled(OrderItemModel item) {
    item.status = OrderItemStatus.canceled;
    updateState();
  }

  void updateQuantity(OrderItemModel item, int newQuantity) {
    item.quantity = newQuantity;
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
          item.status = OrderItemStatus.itemNotAvailable;
        }
        if (pickedBarcode != null && item.sku == pickedBarcode) {
          item.status = OrderItemStatus.picked;
        }
      }
      updateState();
    }
  }

  // Helper method to update an item in all lists
  void _updateItemInLists(OrderItemModel oldItem, OrderItemModel newItem) {
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
            toPick: currentState.toPick,
            picked: currentState.picked,
            canceled: currentState.canceled,
            notAvailable: currentState.notAvailable,
            categories: currentState.categories,
            preparationLabel: currentState.preparationLabel,
            deliveryNote: currentState.deliveryNote,
            expressItems: currentState.expressItems,
            normalItems: currentState.normalItems,
            expressCategories: currentState.expressCategories,
            normalCategories: currentState.normalCategories,
          ),
        );
      }
    }
  }

  void updateState() {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      // Re-categorize items based on their current status
      final allItems = [
        ...currentState.toPick,
        ...currentState.picked,
        ...currentState.canceled,
        ...currentState.notAvailable,
      ];

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

      if (!isClosed) {
        emit(
          OrderDetailsLoaded(
            toPick: toPick,
            picked: picked,
            canceled: canceled,
            notAvailable: notAvailable,
            categories: currentState.categories,
            preparationLabel: currentState.preparationLabel,
            deliveryNote: currentState.deliveryNote,
            expressItems: currentState.expressItems,
            normalItems: currentState.normalItems,
            expressCategories: currentState.expressCategories,
            normalCategories: currentState.normalCategories,
          ),
        );
      }
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
        emit(OrderDetailsError('No authentication token found'));
        return;
      }

      final response = await apiService.updateOrderStatus(
        'cancel_request',
        int.parse(orderId),
        token,
        orderNumber: orderNumber,
        cancelReason: cancelReason,
      );

      print('🔍 Cancel order API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        emit(OrderDetailsError('Order canceled successfully'));
      } else {
        emit(OrderDetailsError('Failed to cancel order'));
      }
    } catch (e) {
      print('❌ Error canceling order: $e');
      emit(OrderDetailsError(e.toString()));
    }
  }

  Future<void> endPicking({required String orderNumber}) async {
    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        emit(OrderDetailsError('No authentication token found'));
        return;
      }

      final response = await apiService.updateOrderStatus(
        'end_picking',
        int.parse(orderId),
        token,
        orderNumber: orderNumber,
      );

      if (response.statusCode == 200) {
        emit(OrderDetailsError('Picking ended successfully'));
      } else {
        emit(OrderDetailsError('Failed to end picking'));
      }
    } catch (e) {
      emit(OrderDetailsError(e.toString()));
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
}
