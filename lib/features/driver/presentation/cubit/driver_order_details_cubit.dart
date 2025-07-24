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
}
