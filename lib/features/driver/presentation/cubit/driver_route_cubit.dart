import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../core/config/app_config.dart';
import '../../data/models/driver_order_model.dart';
import 'driver_route_state.dart';

class DriverRouteCubit extends Cubit<DriverRouteState> {
  DriverRouteCubit() : super(DriverRouteLoading());

  Future<void> loadRoute(
    List<DriverOrderModel> orders,
    LatLng driverLocation,
  ) async {
    emit(DriverRouteLoading());
    try {
      log("🗺️ Starting route calculation");
      log(
        "📍 Driver location: ${driverLocation.latitude}, ${driverLocation.longitude}",
      );
      log("📦 Number of orders: ${orders.length}");

      // Collect waypoints: driver location + all order locations
      final waypoints = <LatLng>[driverLocation];
      for (final order in orders) {
        try {
          final pickupLat = double.parse(order.pickup.latitude);
          final pickupLng = double.parse(order.pickup.longitude);
          final dropoffLat = double.parse(order.dropoff.latitude);
          final dropoffLng = double.parse(order.dropoff.longitude);

          waypoints.add(LatLng(pickupLat, pickupLng));
          waypoints.add(LatLng(dropoffLat, dropoffLng));

          log(
            "📍 Order ${order.id}: Pickup($pickupLat, $pickupLng), Dropoff($dropoffLat, $dropoffLng)",
          );
        } catch (e) {
          log("❌ Error parsing coordinates for order ${order.id}: $e");
          emit(DriverRouteError('Invalid coordinates for order ${order.id}'));
          return;
        }
      }

      if (waypoints.length < 2) {
        log("❌ Not enough waypoints: ${waypoints.length}");
        if (orders.isEmpty) {
          emit(const DriverRouteError('No orders available to show route.'));
        } else {
          emit(const DriverRouteError('Not enough locations to show route.'));
        }
        return;
      }

      log("📍 Total waypoints: ${waypoints.length}");

      final apiKey = AppConfig.google_api_key;
      if (apiKey.isEmpty) {
        log("❌ Google API key is empty");
        emit(const DriverRouteError('Google Maps API key not configured.'));
        return;
      }

      final origin = waypoints.first;
      final destination = waypoints.last;
      final intermediates = waypoints.sublist(1, waypoints.length - 1);

      if (intermediates.isEmpty) {
        log("⚠️ No intermediate waypoints, creating simple route");
        // Create a simple route with just origin and destination
        final markers = await _createSimpleMarkers(origin, destination);
        final polylines = await _createRoutePolylines(
          [origin, destination],
          waypoints,
          [],
        );
        emit(
          DriverRouteLoaded(
            markers: markers,
            polylines: polylines,
            waypoints: waypoints,
            totalDistance: 0.0, // Simple route, no distance calculation
            totalDuration: 0, // Simple route, no duration calculation
          ),
        );
        return;
      }

      final waypointsParam = intermediates
          .map((point) => "${point.latitude},${point.longitude}")
          .join('|');

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin.latitude},${origin.longitude}&"
        "destination=${destination.latitude},${destination.longitude}&"
        "waypoints=optimize:true|$waypointsParam&"
        "key=$apiKey",
      );

      log("🌐 Requesting route from Google Directions API");
      log("🔗 URL: ${url.toString().replaceAll(apiKey, 'API_KEY_HIDDEN')}");

      final response = await http.get(url);
      log("📡 Response status: ${response.statusCode}");

      if (response.statusCode != 200) {
        log("❌ HTTP error: ${response.statusCode}");
        emit(DriverRouteError('HTTP error: ${response.statusCode}'));
        return;
      }

      final data = json.decode(response.body);
      log("📊 API response status: ${data['status']}");

      if (data['status'] == 'OK') {
        final routes = data['routes'] as List;
        if (routes.isEmpty) {
          log("❌ No routes returned");
          emit(const DriverRouteError('No routes found.'));
          return;
        }

        final route = routes[0];
        final overviewPolyline = route['overview_polyline'];
        final points = overviewPolyline['points'] as String;

        // Extract distance and duration from legs
        double totalDistance = 0.0;
        int totalDuration = 0;

        final legs = route['legs'] as List;
        for (final leg in legs) {
          final distance = leg['distance'];
          final duration = leg['duration'];

          if (distance != null && distance['value'] != null) {
            totalDistance +=
                (distance['value'] as int) /
                1000.0; // Convert meters to kilometers
          }

          if (duration != null && duration['value'] != null) {
            totalDuration +=
                (duration['value'] as int) ~/
                60; // Convert seconds to minutes using integer division
          }
        }

        log("🛣️ Decoding polyline points");
        final routeCoordinates = await _decodePolyline(points);
        log("📍 Route coordinates: ${routeCoordinates.length} points");

        // Debug: Log first and last few coordinates
        if (routeCoordinates.isNotEmpty) {
          log(
            "📍 First coordinate: ${routeCoordinates.first.latitude}, ${routeCoordinates.first.longitude}",
          );
          log(
            "📍 Last coordinate: ${routeCoordinates.last.latitude}, ${routeCoordinates.last.longitude}",
          );
          if (routeCoordinates.length > 10) {
            log(
              "📍 Middle coordinate: ${routeCoordinates[routeCoordinates.length ~/ 2].latitude}, ${routeCoordinates[routeCoordinates.length ~/ 2].longitude}",
            );
          }
        }

        final waypointOrder = route['waypoint_order'] as List<dynamic>? ?? [];
        log("📋 Waypoint order: $waypointOrder");

        final markers = await _createMarkers(waypoints, waypointOrder);

        // Create separate polylines for outbound and return routes
        // Set to true to debug with single polyline
        const bool debugSinglePolyline = false;

        Set<Polyline> polylines;
        if (debugSinglePolyline) {
          // Debug: Show single polyline
          polylines = {
            Polyline(
              polylineId: const PolylineId('debugRoute'),
              points: routeCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          };
          log("🔧 Debug mode: Showing single polyline");
        } else {
          // Normal: Show separate outbound and return routes
          polylines = await _createRoutePolylines(
            routeCoordinates,
            waypoints,
            waypointOrder,
          );
        }

        log("✅ Route calculation completed successfully");
        log("📍 Markers: ${markers.length}");
        log("🛣️ Polylines: ${polylines.length}");
        log("📏 Total Distance: ${totalDistance.toStringAsFixed(2)} km");
        log("⏱️ Total Duration: ${totalDuration} minutes");

        emit(
          DriverRouteLoaded(
            markers: markers,
            polylines: polylines,
            waypoints: waypoints,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
          ),
        );
      } else {
        final errorMessage = data['error_message'] ?? 'Unknown error';
        log("❌ Google Directions API error: ${data['status']} - $errorMessage");
        emit(
          DriverRouteError(
            'Failed to fetch route: ${data['status']} - $errorMessage',
          ),
        );
      }
    } catch (e) {
      log("❌ Exception in loadRoute: $e");
      emit(DriverRouteError('Error: $e'));
    }
  }

  Future<Set<Polyline>> _createRoutePolylines(
    List<LatLng> routeCoordinates,
    List<LatLng> waypoints,
    List<dynamic> waypointOrder,
  ) async {
    Set<Polyline> polylines = {};

    if (waypoints.length <= 2) {
      // Simple route - just one polyline
      polylines.add(
        Polyline(
          polylineId: const PolylineId('simpleRoute'),
          points: routeCoordinates,
          color: Colors.blue,
          width: 5,
        ),
      );
      return polylines;
    }

    // For multi-stop routes, we need to identify the return route
    // The return route is from the last delivery back to the starting point
    final origin = waypoints.first;
    final lastDelivery = waypoints.last;

    // Find the index where the return route starts
    // This is the point where we start heading back to origin
    int returnRouteStartIndex = -1;

    // Method 1: Look for the point closest to the last delivery with a larger threshold
    for (int i = 0; i < routeCoordinates.length; i++) {
      final distance = _calculateDistance(routeCoordinates[i], lastDelivery);
      if (distance < 0.5) {
        // Increased to 500 meters for better detection
        returnRouteStartIndex = i;
        log(
          "📍 Found return point at index $i (distance: ${distance.toStringAsFixed(3)} km)",
        );
        break;
      }
    }

    // Method 2: If still not found, look for the point where we start moving away from last delivery
    if (returnRouteStartIndex == -1) {
      log("🔍 Method 1 failed, trying direction analysis...");

      // Find the point where we're closest to the last delivery
      double minDistance = double.infinity;
      int closestIndex = -1;

      for (int i = 0; i < routeCoordinates.length; i++) {
        final distance = _calculateDistance(routeCoordinates[i], lastDelivery);
        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }

      if (closestIndex != -1 && minDistance < 2.0) {
        // Within 2km
        returnRouteStartIndex = closestIndex;
        log(
          "📍 Found closest point to last delivery at index $closestIndex (distance: ${minDistance.toStringAsFixed(3)} km)",
        );
      }
    }

    // Method 3: Fallback - use the last quarter of the route
    if (returnRouteStartIndex == -1) {
      returnRouteStartIndex = (routeCoordinates.length * 3 / 4).round();
      log(
        "⚠️ Using fallback: return route starts at ${returnRouteStartIndex} (last quarter)",
      );
    }

    // Ensure we have a reasonable split (at least 20% for outbound, 10% for return)
    final minOutboundPoints = (routeCoordinates.length * 0.2).round();
    final minReturnPoints = (routeCoordinates.length * 0.1).round();

    if (returnRouteStartIndex < minOutboundPoints) {
      returnRouteStartIndex = minOutboundPoints;
      log("⚠️ Adjusted return point to ensure minimum outbound route length");
    }

    if (returnRouteStartIndex > routeCoordinates.length - minReturnPoints) {
      returnRouteStartIndex = routeCoordinates.length - minReturnPoints;
      log("⚠️ Adjusted return point to ensure minimum return route length");
    }

    // Create outbound route (from start to last delivery)
    final outboundPoints = routeCoordinates.sublist(
      0,
      returnRouteStartIndex + 1,
    );
    polylines.add(
      Polyline(
        polylineId: const PolylineId('outboundRoute'),
        points: outboundPoints,
        color: Colors.blue,
        width: 5,
      ),
    );

    // Create return route (from last delivery back to start)
    final returnPoints = routeCoordinates.sublist(returnRouteStartIndex);
    polylines.add(
      Polyline(
        polylineId: const PolylineId('returnRoute'),
        points: returnPoints,
        color: Colors.red,
        width: 5,
      ),
    );

    log(
      "🛣️ Created outbound route: ${outboundPoints.length} points (${(outboundPoints.length / routeCoordinates.length * 100).toStringAsFixed(1)}%)",
    );
    log(
      "🛣️ Created return route: ${returnPoints.length} points (${(returnPoints.length / routeCoordinates.length * 100).toStringAsFixed(1)}%)",
    );

    return polylines;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  Future<Set<Marker>> _createSimpleMarkers(
    LatLng origin,
    LatLng destination,
  ) async {
    Set<Marker> markers = {};

    // Origin marker
    markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: origin,
        infoWindow: const InfoWindow(title: 'Start'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    return markers;
  }

  Future<Set<Marker>> _createMarkers(
    List<LatLng> waypoints,
    List<dynamic> order,
  ) async {
    Set<Marker> markers = {};
    // Origin
    markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: waypoints.first,
        infoWindow: const InfoWindow(title: 'Start'),
        icon: await _createNumberMarker(1, Colors.blue),
      ),
    );
    // Optimized waypoints
    for (int i = 0; i < order.length; i++) {
      final pointIndex = order[i] + 1;
      markers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: waypoints[pointIndex],
          infoWindow: InfoWindow(title: 'Stop ${i + 2}'),
          icon: await _createNumberMarker(i + 2, Colors.green),
        ),
      );
    }
    // Destination
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: waypoints.last,
        infoWindow: InfoWindow(title: 'Destination'),
        icon: await _createNumberMarker(waypoints.length, Colors.red),
      ),
    );
    return markers;
  }

  Future<BitmapDescriptor> _createNumberMarker(int number, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    const double size = 50.0;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    textPainter.text = TextSpan(
      text: number.toString(),
      style: const TextStyle(
        fontSize: 20.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<List<LatLng>> _decodePolyline(String encoded) async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.decodePolyline(encoded);
    return result
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }
}
