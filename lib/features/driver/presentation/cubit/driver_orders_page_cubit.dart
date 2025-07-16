import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_gateway/services/api_service.dart';

part 'driver_orders_page_state.dart';

class DriverOrdersPageCubit extends Cubit<DriverOrdersPageState> {
  late final ApiService _apiService;

  DriverOrdersPageCubit({required ApiService apiService})
    : super(DriverOrdersPageInitial()) {
    _apiService = apiService;
    // _apiService.connectWebSocket(); // Connect once
  }

  updateData() {
    _apiService.getOrders().then((value) {
      emit(
        DriverOrdersPageLoaded(
          position: Position(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        ),
      );
    });
  }

  void updateLocation(Position position) {
    emit(DriverOrdersPageLoaded(position: position));
    sendLocationToBackend(position.latitude, position.longitude);
  }

  void reset() {
    emit(DriverOrdersPageInitial());
  }

  Future<void> sendLocationToBackend(double lat, double lng) async {
    print("Sending location: $lat, $lng");
    try {
      await _apiService.sendLocation(lat, lng);
    } catch (e) {
      print("Failed to send location: $e");
    }
  }

  @override
  Future<void> close() {
    // Optionally disconnect WebSocket here if needed
    // _wsClient.disconnect();
    return super.close();
  }
}
