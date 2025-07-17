import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import 'package:api_gateway/services/api_service.dart';
import '../../../../core/services/user_storage_service.dart';

part 'order_details_state.dart';

class OrderDetailsCubit extends Cubit<OrderDetailsState> {
  final String orderId;
  final ApiService apiService;

  OrderDetailsCubit({required this.orderId, required this.apiService})
    : super(OrderDetailsLoading()) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    emit(OrderDetailsLoading());
    try {
      final user = await UserStorageService.getUserData();
      final token = user?.token;
      if (token == null) {
        emit(OrderDetailsError('No token found'));
        return;
      }
      final data = await apiService.fetchPickerOrderDetails(orderId, token);
      final order = OrderModel.fromJson(data);
      emit(
        OrderDetailsLoaded(
          toPick:
              order.items
                  .where((i) => i.status == OrderItemStatus.toPick)
                  .toList(),
          picked:
              order.items
                  .where((i) => i.status == OrderItemStatus.picked)
                  .toList(),
          canceled:
              order.items
                  .where((i) => i.status == OrderItemStatus.canceled)
                  .toList(),
          notAvailable:
              order.items
                  .where((i) => i.status == OrderItemStatus.notAvailable)
                  .toList(),
        ),
      );
    } catch (e) {
      emit(OrderDetailsError(e.toString()));
    }
  }

  void markPicked(OrderItemModel item) {
    item.status = OrderItemStatus.picked;
    _loadItems();
  }

  void markOutOfStock(OrderItemModel item) {
    item.status = OrderItemStatus.notAvailable;
    _loadItems();
  }

  void markCanceled(OrderItemModel item) {
    item.status = OrderItemStatus.canceled;
    _loadItems();
  }

  void updateQuantity(OrderItemModel item, int newQuantity) {
    item.quantity = newQuantity;
    _loadItems();
  }
}
