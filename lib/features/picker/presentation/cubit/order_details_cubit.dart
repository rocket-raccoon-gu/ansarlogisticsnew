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
        ),
      );
    } else {
      emit(OrderDetailsLoading(preparationId: int.parse(orderId)));
    }

    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        emit(OrderDetailsError('No authentication token found'));
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

        emit(
          OrderDetailsLoaded(
            toPick: toPick,
            picked: picked,
            canceled: canceled,
            notAvailable: notAvailable,
            categories: orderDetails.categories,
          ),
        );
      } else {
        emit(OrderDetailsError('No data received from server'));
      }
    } catch (e) {
      emit(OrderDetailsError(e.toString()));
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
        emit(OrderDetailsError('No authentication token found'));
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

        updateState();
        return true;
      } else {
        emit(OrderDetailsError('Failed to update item status'));
        return false;
      }
    } catch (e) {
      emit(OrderDetailsError(e.toString()));
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

      emit(
        OrderDetailsLoaded(
          toPick: toPick,
          picked: picked,
          canceled: canceled,
          notAvailable: notAvailable,
          categories: currentState.categories,
        ),
      );
    }
  }

  Future<void> reloadItemsFromApi() async {
    _cachedOrderDetails = null;
    await loadItems();
  }

  Future<void> cancelOrder({required String orderNumber}) async {
    try {
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
      );
      if (response.statusCode == 200) {
        emit(OrderDetailsError('Order canceled successfully'));
      } else {
        emit(OrderDetailsError('Failed to cancel order'));
      }
    } catch (e) {
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
        'end_pick',
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
}
