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

  OrderDetailsCubit({required this.orderId, required this.apiService})
    : super(OrderDetailsInitial());

  Future<void> loadItems() async {
    emit(OrderDetailsLoading());
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
                .where((item) => item.status == OrderItemStatus.notAvailable)
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

  void markPicked(OrderItemModel item) {
    item.status = OrderItemStatus.picked;
    _updateState();
  }

  void markOutOfStock(OrderItemModel item) {
    item.status = OrderItemStatus.notAvailable;
    _updateState();
  }

  void markCanceled(OrderItemModel item) {
    item.status = OrderItemStatus.canceled;
    _updateState();
  }

  void updateQuantity(OrderItemModel item, int newQuantity) {
    item.quantity = newQuantity;
    _updateState();
  }

  void _updateState() {
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
              .where((item) => item.status == OrderItemStatus.notAvailable)
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
}
