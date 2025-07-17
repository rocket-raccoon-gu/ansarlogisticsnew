import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../core/config/app_config.dart';
import '../../../picker/data/models/order_model.dart';
import 'driver_route_state.dart';

class DriverRouteCubit extends Cubit<DriverRouteState> {
  DriverRouteCubit() : super(DriverRouteLoading());

  Future<void> loadRoute(List<OrderModel> orders, LatLng driverLocation) async {
    emit(DriverRouteLoading());
    try {
      // Collect waypoints: driver location + all order locations
      final waypoints = <LatLng>[driverLocation];
      for (final order in orders) {
        if (order.customerZone != null && order.customerZone!.isNotEmpty) {
          waypoints.add(LatLng(25.163422, 51.426304));
        }
      }
      if (waypoints.length < 2) {
        emit(const DriverRouteError('Not enough locations to show route.'));
        return;
      }
      final apiKey = AppConfig.googleMapApiKey;
      final origin = waypoints.first;
      final destination = waypoints.last;
      final intermediates = waypoints.sublist(1, waypoints.length - 1);
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
      log(url.toString());
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final points = data['routes'][0]['overview_polyline']['points'];
        final routeCoordinates = await _decodePolyline(points);
        final waypointOrder =
            data['routes'][0]['waypoint_order'] as List<dynamic>;
        final markers = await _createMarkers(waypoints, waypointOrder);
        final polylines = {
          Polyline(
            polylineId: PolylineId('multiRoute'),
            points: routeCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        };
        emit(
          DriverRouteLoaded(
            markers: markers,
            polylines: polylines,
            waypoints: waypoints,
          ),
        );
      } else {
        emit(DriverRouteError('Failed to fetch route: ${data['status']}'));
      }
    } catch (e) {
      emit(DriverRouteError('Error: $e'));
    }
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
