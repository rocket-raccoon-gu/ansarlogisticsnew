part of 'picker_orders_cubit.dart';

abstract class PickerOrdersState {}

class PickerOrdersLoading extends PickerOrdersState {}

class PickerOrdersRefreshing extends PickerOrdersState {
  final List<OrderModel> orders;
  PickerOrdersRefreshing(this.orders);
}

class PickerOrdersLoaded extends PickerOrdersState {
  final List<OrderModel> orders;
  PickerOrdersLoaded(this.orders);
}

class PickerOrdersError extends PickerOrdersState {
  final String message;
  PickerOrdersError(this.message);
}
