import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/driver_order_model.dart';
import '../cubit/driver_route_cubit.dart';
import '../cubit/driver_route_state.dart';

class DriverRoutePage extends StatelessWidget {
  final List<DriverOrderModel> orders;
  final LatLng driverLocation;
  const DriverRoutePage({
    super.key,
    required this.orders,
    required this.driverLocation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DriverRouteCubit()..loadRoute(orders, driverLocation),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Route')),
        body: BlocBuilder<DriverRouteCubit, DriverRouteState>(
          builder: (context, state) {
            if (state is DriverRouteLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DriverRouteError) {
              return Center(child: Text(state.message));
            }
            if (state is DriverRouteLoaded) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: driverLocation,
                  zoom: 11,
                ),
                markers: state.markers,
                polylines: state.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
