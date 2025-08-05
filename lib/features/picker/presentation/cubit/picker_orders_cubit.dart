import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_gateway/api_gateway.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../../../core/services/user_storage_service.dart';

part 'picker_orders_state.dart';

class PickerOrdersCubit extends Cubit<PickerOrdersState> {
  PickerOrdersCubit() : super(PickerOrdersLoading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!isClosed) {
      emit(PickerOrdersLoading());
    }
    await _loadOrders();
  }

  Future<void> refreshOrders() async {
    // Emit refreshing state to show refresh loader
    final currentState = state;
    if (currentState is PickerOrdersLoaded) {
      if (!isClosed) {
        emit(PickerOrdersRefreshing(currentState.orders));
      }
    }
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!isClosed) {
          emit(PickerOrdersError('No authentication token found'));
        }
        return;
      }

      final response = await ApiGateway(
        apiService: ApiService(HttpClient(), WebSocketClient()),
      ).getOrders(token);

      if (response.data != null) {
        log('Orders: ${response.data}');
        Map<String, dynamic> data = response.data as Map<String, dynamic>;

        final List<OrderModel> orders =
            (data['data'] as List)
                .map((orderJson) => OrderModel.fromJson(orderJson))
                .toList();
        if (!isClosed) {
          emit(PickerOrdersLoaded(orders));
        }
      } else {
        // For demo purposes, create some sample orders
        final List<OrderModel> sampleOrders = [
          OrderModel(
            // preparationId: 'ORD001',
            preparationLabel: 'ORD001',
            status: 'pending',
            deliveryFrom: DateTime.now().add(const Duration(days: 2)),
            customerFirstname: 'John Doe',
            customerEmail: 'john.doe@example.com',
            customerZone: 'Zone A',
            phone: '1234567890',
            itemCount: 1,
            branchCode: 'BR001',
            customerId: 1,
            createdAt: DateTime.now(),
            pickerId: 1,
            driverId: 1,
            deliveryTo: DateTime.now().add(const Duration(days: 2)),
            timerange: '10:00 - 12:00',
            items: [],
          ),
        ];
        if (!isClosed) {
          emit(PickerOrdersLoaded(sampleOrders));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(PickerOrdersError(e.toString()));
      }
    }
  }
}
