import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/driver_order_model.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';

part 'driver_order_details_state.dart';

class DriverOrderDetailsCubit extends Cubit<DriverOrderDetailsState> {
  final ApiService _apiService;

  DriverOrderDetailsCubit({ApiService? apiService})
    : _apiService = apiService ?? ApiService(HttpClient(), WebSocketClient()),
      super(DriverOrderDetailsInitial());

  Future<void> fetchOrderDetails(String orderId, String token) async {
    emit(DriverOrderDetailsLoading());
    try {
      final response = await _apiService.getDriverOrderDetails(orderId, token);
      final details = DriverOrderDetailsModel.fromJson(response.data);
      emit(DriverOrderDetailsLoaded(details));
    } catch (e) {
      emit(DriverOrderDetailsError(e.toString()));
    }
  }

  Future<void> updateOrderStatusDriver(
    String token,
    String preparationId,
    String orderStatus,
  ) async {
    emit(DriverOrderDetailsLoading());
    final startTime = DateTime.now();
    try {
      print('Starting API call for order status update...');
      // Add timeout to prevent hanging
      await _apiService
          .updateOrderStatusDriver(token, preparationId, orderStatus)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timed out. Please try again.');
            },
          );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('API call completed in ${duration.inMilliseconds}ms');
      emit(DriverOrderOnTheWaySuccess(orderStatus));
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('API call failed after ${duration.inMilliseconds}ms: $e');
      emit(DriverOrderDetailsError(e.toString()));
    }
  }
}
