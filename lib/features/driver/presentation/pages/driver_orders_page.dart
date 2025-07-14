import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class DriverOrdersPage extends StatefulWidget {
  @override
  _DriverOrdersPageState createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  final List<LatLng> _movementPath = [];
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    await Permission.locationWhenInUse.request();

    if (await Permission.location.isGranted) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) async {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPos;
          _movementPath.add(newPos);
        });

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLng(newPos));
      });
    } else {
      await Permission.location.request();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Orders & Live Location")),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 17,
              ),
              polylines: {
                Polyline(
                  polylineId: PolylineId('movement'),
                  color: Colors.blue,
                  width: 4,
                  points: _movementPath,
                )
              },
              markers: {
                Marker(
                  markerId: MarkerId("current"),
                  position: _currentPosition!,
                  infoWindow: InfoWindow(title: "You"),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
