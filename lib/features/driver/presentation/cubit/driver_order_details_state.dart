part of 'driver_order_details_cubit.dart';

abstract class DriverOrderDetailsState extends Equatable {
  const DriverOrderDetailsState();
  @override
  List<Object?> get props => [];
}

class DriverOrderDetailsInitial extends DriverOrderDetailsState {}

class DriverOrderDetailsLoading extends DriverOrderDetailsState {}

class DriverOrderDetailsLoaded extends DriverOrderDetailsState {
  final DriverOrderDetailsModel details;
  final String? username;
  const DriverOrderDetailsLoaded(this.details, this.username);
  @override
  List<Object?> get props => [details, username];
}

class DriverOrderDetailsError extends DriverOrderDetailsState {
  final String message;
  const DriverOrderDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}

class DriverOrderOnTheWaySuccess extends DriverOrderDetailsState {
  final String orderStatus;
  const DriverOrderOnTheWaySuccess(this.orderStatus);
  @override
  List<Object?> get props => [orderStatus];
}
