import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/driver_order_model.dart';
import '../cubit/driver_route_cubit.dart';
import '../cubit/driver_route_state.dart';
import 'dart:developer';
import 'dart:math' hide log;

class DriverRoutePage extends StatefulWidget {
  final List<DriverOrderModel> orders;
  final LatLng driverLocation;

  const DriverRoutePage({
    super.key,
    required this.orders,
    required this.driverLocation,
  });

  @override
  State<DriverRoutePage> createState() => _DriverRoutePageState();
}

class _DriverRoutePageState extends State<DriverRoutePage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    log("🗺️ Initializing Google Maps");
    log(
      "📍 Driver Location: ${widget.driverLocation.latitude}, ${widget.driverLocation.longitude}",
    );
    log("📦 Number of Orders: ${widget.orders.length}");

    // Log order details for debugging
    for (int i = 0; i < widget.orders.length; i++) {
      final order = widget.orders[i];
      log("📦 Order $i: ID=${order.id}");
      log("   Pickup: ${order.pickup.latitude}, ${order.pickup.longitude}");
      log("   Dropoff: ${order.dropoff.latitude}, ${order.dropoff.longitude}");
    }

    // Create initial markers for debugging
    _createInitialMarkers();
  }

  void _createInitialMarkers() {
    _markers.clear();

    // Add driver location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: widget.driverLocation,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Driver starting point',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add order markers
    for (int i = 0; i < widget.orders.length; i++) {
      final order = widget.orders[i];

      try {
        // Pickup location
        final pickupLat = double.parse(order.pickup.latitude);
        final pickupLng = double.parse(order.pickup.longitude);

        _markers.add(
          Marker(
            markerId: MarkerId('pickup_$i'),
            position: LatLng(pickupLat, pickupLng),
            infoWindow: InfoWindow(
              title: 'Pickup ${i + 1}',
              snippet: 'Order #${order.id}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );

        // Dropoff location
        final dropoffLat = double.parse(order.dropoff.latitude);
        final dropoffLng = double.parse(order.dropoff.longitude);

        _markers.add(
          Marker(
            markerId: MarkerId('dropoff_$i'),
            position: LatLng(dropoffLat, dropoffLng),
            infoWindow: InfoWindow(
              title: 'Dropoff ${i + 1}',
              snippet: 'Order #${order.id}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );

        log("✅ Added markers for order ${order.id}");
      } catch (e) {
        log("❌ Error parsing coordinates for order ${order.id}: $e");
        log("   Pickup: ${order.pickup.latitude}, ${order.pickup.longitude}");
        log(
          "   Dropoff: ${order.dropoff.latitude}, ${order.dropoff.longitude}",
        );
      }
    }

    log("📍 Created ${_markers.length} markers");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              DriverRouteCubit()
                ..loadRoute(widget.orders, widget.driverLocation),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Route'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: BlocConsumer<DriverRouteCubit, DriverRouteState>(
          listener: (context, state) {
            if (state is DriverRouteLoaded) {
              log("🗺️ Route loaded successfully");
              log("📍 Markers: ${state.markers.length}");
              log("🛣️ Polylines: ${state.polylines.length}");
              log(
                "📏 Total Distance: ${state.totalDistance.toStringAsFixed(2)} km",
              );
              log("⏱️ Total Duration: ${state.totalDuration} minutes");

              // Debug: Log polyline details
              for (final polyline in state.polylines) {
                log(
                  "🛣️ Polyline: ${polyline.polylineId.value} - ${polyline.points.length} points - Color: ${polyline.color}",
                );
              }

              setState(() {
                _markers = state.markers;
                _polylines = state.polylines;
              });

              // Fit map to show all markers
              _fitMapToMarkers();
            } else if (state is DriverRouteError) {
              log("❌ Route error: ${state.message}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Route Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is DriverRouteLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading route...'),
                  ],
                ),
              );
            }

            if (state is DriverRouteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load route',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DriverRouteCubit>().loadRoute(
                          widget.orders,
                          widget.driverLocation,
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    log("🗺️ Map controller created");
                    _fitMapToMarkers();
                  },
                  initialCameraPosition: CameraPosition(
                    target: widget.driverLocation,
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  compassEnabled: true,
                  onTap: (LatLng position) {
                    log(
                      "📍 Map tapped at: ${position.latitude}, ${position.longitude}",
                    );
                  },
                ),

                // Route Info Panel
                if (state is DriverRouteLoaded)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Route Summary',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.straighten,
                                  title: 'Total Distance',
                                  value:
                                      '${state.totalDistance.toStringAsFixed(1)} km',
                                  color: Colors.green[600]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.access_time,
                                  title: 'Total Duration',
                                  value: '${state.totalDuration} min',
                                  color: Colors.orange[600]!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.local_shipping,
                                  title: 'Orders',
                                  value: '${widget.orders.length}',
                                  color: Colors.purple[600]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.location_on,
                                  title: 'Stops',
                                  value:
                                      '${_markers.length - 1}', // Exclude driver location
                                  color: Colors.red[600]!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Route Legend
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Route Colors: Blue = Outbound, Red = Return',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Center Map Button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _fitMapToMarkers();
                    },
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.center_focus_strong),
                    tooltip: 'Center Map',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _fitMapToMarkers() {
    if (_mapController == null || _markers.isEmpty) {
      log("⚠️ Cannot fit map: controller is null or no markers");
      return;
    }

    try {
      final bounds = _calculateBounds();
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      log("🗺️ Map fitted to markers");
    } catch (e) {
      log("❌ Error fitting map to markers: $e");
    }
  }

  LatLngBounds _calculateBounds() {
    if (_markers.isEmpty) {
      return LatLngBounds(
        southwest: widget.driverLocation,
        northeast: widget.driverLocation,
      );
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
