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

  // New fields for delivery type groups
  final List<OrderItemModel> expressItems;
  final List<OrderItemModel> normalItems;
  final List<CategoryItemModel> expressCategories;
  final List<CategoryItemModel> normalCategories;

  OrderDetailsLoaded({
    required this.toPick,
    required this.picked,
    required this.canceled,
    required this.notAvailable,
    required this.categories,
    required this.preparationLabel,
    this.deliveryNote,
    required this.expressItems,
    required this.normalItems,
    required this.expressCategories,
    required this.normalCategories,
  });
}

class OrderDetailsError extends OrderDetailsState {
  final String message;
  OrderDetailsError(this.message);
}
