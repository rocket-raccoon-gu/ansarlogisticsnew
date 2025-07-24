import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_gateway/services/api_service.dart';
import '../../data/models/driver_order_model.dart';
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

  List<DriverOrderModel> orders = [];

  void loadOrders() async {
    emit(DriverOrdersPageLoading());
    try {
      final user = await UserStorageService.getUserData();
      final token = user?.token;
      if (token != null) {
        final response = await _apiService.getDriverOrders(token);
        if (response.statusCode == 200 &&
            response.data != null &&
            (response.data['success'] == true ||
                response.data['success'] == null)) {
          final List<DriverOrderModel> fetchedOrders =
              (response.data['data'] as List)
                  .map(
                    (e) => DriverOrderModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList();
          orders = fetchedOrders;
          emit(DriverOrdersPageLoaded(orders: orders));
        } else {
          emit(DriverOrdersPageLoaded(orders: []));
        }
      } else {
        emit(DriverOrdersPageLoaded(orders: []));
      }
    } catch (e) {
      emit(DriverOrdersPageLoaded(orders: []));
    }
  }

  updateData() {
    UserStorageService.getUserData().then((value) {
      final token = value?.token;
      if (token != null) {
        _apiService.getDriverOrders(token).then((response) {
          final List<DriverOrderModel> fetchedOrders =
              (response.data['data'] as List)
                  .map(
                    (e) => DriverOrderModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList();
          emit(
            DriverOrdersPageLoaded(
              orders: fetchedOrders,
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
