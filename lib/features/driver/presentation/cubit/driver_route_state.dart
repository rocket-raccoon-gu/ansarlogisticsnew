import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class DriverRouteState extends Equatable {
  const DriverRouteState();
  @override
  List<Object?> get props => [];
}

class DriverRouteLoading extends DriverRouteState {}

class DriverRouteLoaded extends DriverRouteState {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<LatLng> waypoints;
  final double totalDistance; // in kilometers
  final int totalDuration; // in minutes

  const DriverRouteLoaded({
    required this.markers,
    required this.polylines,
    required this.waypoints,
    required this.totalDistance,
    required this.totalDuration,
  });

  @override
  List<Object?> get props => [
    markers,
    polylines,
    waypoints,
    totalDistance,
    totalDuration,
  ];
}

class DriverRouteError extends DriverRouteState {
  final String message;
  const DriverRouteError(this.message);
  @override
  List<Object?> get props => [message];
}
