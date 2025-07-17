import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_gateway/services/api_service.dart';
import '../../../picker/data/models/order_model.dart';
import '../../../../core/services/user_storage_service.dart';

part 'driver_orders_page_state.dart';

class DriverOrdersPageCubit extends Cubit<DriverOrdersPageState> {
  late final ApiService _apiService;

  DriverOrdersPageCubit({required ApiService apiService})
    : super(DriverOrdersPageInitial()) {
    _apiService = apiService;
    // _apiService.connectWebSocket(); // Connect once
    loadOrders();
  }

  List<OrderModel> orders = [
    OrderModel(
      preparationId: 'DORD001',
      status: 'pending',
      deliveryFrom: DateTime.now().add(const Duration(days: 1)),
      customerFirstname: 'Driver Customer 1',
      customerZone: '123 Main St, City',
      phone: '1234567890',
      itemCount: 1,
      branchCode: 'BR001',
      customerId: 1,
      customerEmail: 'driver1@example.com',
      createdAt: DateTime.now(),
      pickerId: 1,
      items: [],
    ),
    OrderModel(
      preparationId: 'DORD002',
      status: 'completed',
      deliveryFrom: DateTime.now().subtract(const Duration(days: 1)),
      customerFirstname: 'Driver Customer 2',
      customerZone: '456 Elm St, City',
      phone: '1234567890',
      itemCount: 1,
      branchCode: 'BR001',
      customerId: 1,
      customerEmail: 'driver1@example.com',
      createdAt: DateTime.now(),
      pickerId: 1,
      items: [],
    ),
  ];

  void loadOrders() {
    emit(DriverOrdersPageLoaded(orders: orders));
  }

  updateData() {
    UserStorageService.getUserData().then((value) {
      final token = value?.token;
      if (token != null) {
        _apiService.getOrders(token).then((value) {
          emit(
            DriverOrdersPageLoaded(
              orders: value.data,
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
    });
  }

  void updateLocation(Position position) {
    emit(DriverOrdersPageLoaded(orders: orders, position: position));
    UserStorageService.getUserData().then((value) {
      final token = value?.token;
      if (token != null) {
        _apiService.getOrders(token).then((value) {
          emit(
            DriverOrdersPageLoaded(
              orders: value.data,
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
    });

    emit(DriverOrdersPageLoaded(orders: orders, position: position));
    sendLocationToBackend(position.latitude, position.longitude);
  }

  // void updateLocation(Position position) {
  //   emit(DriverOrdersPageLoaded(orders: orders, position: position));
  //   sendLocationToBackend(position.latitude, position.longitude);
  // }

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
