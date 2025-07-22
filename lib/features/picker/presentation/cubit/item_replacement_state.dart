part of 'item_replacement_page_cubit.dart';

abstract class ItemReplacementState {}

class ItemReplacementInitial extends ItemReplacementState {}

class ItemReplacementLoading extends ItemReplacementState {}

class ItemReplacementLoaded extends ItemReplacementState {
  final OrderReplacementProductModel selectedReplacement;
  ItemReplacementLoaded({required this.selectedReplacement});
}

class ItemReplacementSuccess extends ItemReplacementState {
  ItemReplacementSuccess();
}

class ItemReplacementError extends ItemReplacementState {}
