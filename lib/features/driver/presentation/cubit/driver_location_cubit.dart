import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';

class DriverLocationCubit extends Cubit<Position?> {
  Timer? _timer;
  final ApiService _apiService = ApiService(HttpClient(), WebSocketClient());

  DriverLocationCubit() : super(null);

  void startTracking() {
    _timer?.cancel();
    _sendLocation(); // send immediately
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendLocation(),
    );
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    emit(null);
  }

  Future<void> _sendLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      emit(pos);
      await _apiService.sendLocation(pos.latitude, pos.longitude);
    } catch (e) {
      log('Location error: $e');
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
