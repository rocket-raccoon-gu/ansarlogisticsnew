import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';

part 'driver_orders_page_state.dart';

class DriverOrdersPageCubit extends Cubit<DriverOrdersPageState> {
  final HttpClient _httpClient = HttpClient();
  final WebSocketClient _wsClient = WebSocketClient();
  late final ApiService _apiService;

  DriverOrdersPageCubit() : super(DriverOrdersPageInitial()) {
    _apiService = ApiService(_httpClient, _wsClient);
    _apiService.connectWebSocket(); // Connect once
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
