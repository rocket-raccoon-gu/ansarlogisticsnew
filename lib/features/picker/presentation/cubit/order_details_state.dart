part of 'order_details_cubit.dart';

abstract class OrderDetailsState {}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {
  final int preparationId;
  OrderDetailsLoading({required this.preparationId});
}

class OrderDetailsLoaded extends OrderDetailsState {
  final List<OrderItemModel> toPick;
  final List<OrderItemModel> picked;
  final List<OrderItemModel> canceled;
  final List<OrderItemModel> notAvailable;
  final List<CategoryItemModel> categories;
  final String preparationLabel;
  final String? deliveryNote;

  OrderDetailsLoaded({
    required this.toPick,
    required this.picked,
    required this.canceled,
    required this.notAvailable,
    required this.categories,
    required this.preparationLabel,
    this.deliveryNote,
  });
}

class OrderDetailsError extends OrderDetailsState {
  final String message;
  OrderDetailsError(this.message);
}
