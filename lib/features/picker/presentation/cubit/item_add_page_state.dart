part of 'item_add_page_cubit.dart';

abstract class ItemAddPageState {}

class ItemAddPageInitial extends ItemAddPageState {}

class ItemAddPageLoading extends ItemAddPageState {}

class ItemAddPageLoaded extends ItemAddPageState {
  OrderReplacementProductModel product;
  ItemAddPageLoaded(this.product);
}

class ItemAddPageError extends ItemAddPageState {
  final String message;

  ItemAddPageError(this.message);
}

class ItemAddPageSuccess extends ItemAddPageState {
  // final String message;

  ItemAddPageSuccess();
}
