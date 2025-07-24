part of 'driver_orders_page_cubit.dart';

abstract class DriverOrdersPageState extends Equatable {
  const DriverOrdersPageState();

  @override
  List<Object> get props => [];
}

class DriverOrdersPageInitial extends DriverOrdersPageState {}

class DriverOrdersPageLoading extends DriverOrdersPageState {}

class DriverOrdersPageLoaded extends DriverOrdersPageState {
  final List<DriverOrderModel> orders;
  final Position? position;

  const DriverOrdersPageLoaded({required this.orders, this.position});

  @override
  List<Object> get props => [orders, if (position != null) position!];
}
