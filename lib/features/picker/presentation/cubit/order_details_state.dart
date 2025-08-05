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
  final String? expStatus;
  final String? nolStatus;
  final String? warStatus;
  final String? supStatus;
  final String? vpoStatus;
  final String? abyStatus;
  final String? paymentMethod;
  // New fields for delivery type groups
  final List<OrderItemModel> expressItems;
  final List<OrderItemModel> normalItems;
  final List<OrderItemModel> warehouseItems;
  final List<OrderItemModel> supplierItems;
  final List<OrderItemModel> vendorPickupItems;
  final List<OrderItemModel> abayaItems;
  final List<CategoryItemModel> expressCategories;
  final List<CategoryItemModel> normalCategories;
  final List<CategoryItemModel> warehouseCategories;
  final List<CategoryItemModel> supplierCategories;
  final List<CategoryItemModel> vendorPickupCategories;
  final List<CategoryItemModel> abayaCategories;

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
    required this.warehouseItems,
    required this.supplierItems,
    required this.vendorPickupItems,
    required this.abayaItems,
    required this.expressCategories,
    required this.normalCategories,
    required this.warehouseCategories,
    required this.supplierCategories,
    required this.vendorPickupCategories,
    required this.abayaCategories,
    required this.expStatus,
    required this.nolStatus,
    required this.warStatus,
    required this.supStatus,
    required this.vpoStatus,
    required this.abyStatus,
    this.paymentMethod,
  });
}

class OrderDetailsError extends OrderDetailsState {
  final String message;
  OrderDetailsError(this.message);
}
