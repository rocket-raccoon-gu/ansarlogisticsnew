part of 'order_details_cubit.dart';

abstract class OrderDetailsState {}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {}

class OrderDetailsLoaded extends OrderDetailsState {
  final List<OrderItemModel> toPick;
  final List<OrderItemModel> picked;
  final List<OrderItemModel> canceled;
  final List<OrderItemModel> notAvailable;
  final List<CategoryItemModel> categories;

  OrderDetailsLoaded({
    required this.toPick,
    required this.picked,
    required this.canceled,
    required this.notAvailable,
    required this.categories,
  });
}

class OrderDetailsError extends OrderDetailsState {
  final String message;
  OrderDetailsError(this.message);
}
