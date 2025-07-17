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
    emit(PickerOrdersLoading());
    try {
      UserStorageService.getUserData().then((value) async {
        final token = value?.token;
        if (token != null) {
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
            emit(PickerOrdersLoaded(orders));
          } else {
            // For demo purposes, create some sample orders
            final List<OrderModel> sampleOrders = [
              OrderModel(
                preparationId: 'ORD001',
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
            emit(PickerOrdersLoaded(sampleOrders));
          }
        }
      });

      // final response =
      //     await ApiGateway(
      //       apiService: ApiService(HttpClient(), WebSocketClient()),
      //     ).getOrders();

      // if (response.data != null && response.data is List) {
      //   final List<OrderModel> orders =
      //       (response.data as List)
      //           .map((orderJson) => OrderModel.fromJson(orderJson))
      //           .toList();
      //   emit(PickerOrdersLoaded(orders));
      // } else {
      //   // For demo purposes, create some sample orders
      //   final List<OrderModel> sampleOrders = [
      //     OrderModel(
      //       orderId: 'ORD001',
      //       status: 'pending',
      //       deliveryDate: DateTime.now().add(const Duration(days: 2)),
      //       customerComment: 'Please deliver before 2 PM',
      //       customerName: 'John Doe',
      //       customerPhone: '1234567890',
      //       customerWhatsapp: '1234567890',
      //       items: [
      //         OrderItemModel(
      //           id: '1',
      //           name: 'Item 1',
      //           imageUrl: 'https://via.placeholder.com/150',
      //           quantity: 1,
      //           status: OrderItemStatus.toPick,
      //           description: 'Description of Item 1',
      //         ),
      //         OrderItemModel(
      //           id: '2',
      //           name: 'Item 2',
      //           imageUrl: 'https://via.placeholder.com/150',
      //           quantity: 2,
      //           status: OrderItemStatus.picked,
      //         ),
      //       ],
      //     ),
      //     OrderModel(
      //       orderId: 'ORD002',
      //       status: 'in_progress',
      //       deliveryDate: DateTime.now().add(const Duration(days: 1)),
      //       customerComment: 'Fragile items, handle with care',
      //       customerName: 'Jane Doe',
      //       customerPhone: '1234567890',
      //       customerWhatsapp: '1234567890',
      //       items: [
      //         OrderItemModel(
      //           id: '3',
      //           name: 'Item 3',
      //           imageUrl: 'https://via.placeholder.com/150',
      //           quantity: 3,
      //           status: OrderItemStatus.canceled,
      //           description: 'Description of Item 3',
      //         ),
      //         OrderItemModel(
      //           id: '4',
      //           name: 'Item 4',
      //           imageUrl: 'https://via.placeholder.com/150',
      //           quantity: 4,
      //           status: OrderItemStatus.notAvailable,
      //         ),
      //       ],
      //     ),
      //     OrderModel(
      //       orderId: 'ORD003',
      //       status: 'completed',
      //       deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
      //       customerComment: null,
      //       customerName: 'John Doe',
      //       customerPhone: '1234567890',
      //       customerWhatsapp: '1234567890',
      //       items: [
      //         OrderItemModel(
      //           id: '5',
      //           name: 'Item 5',
      //           imageUrl: 'https://via.placeholder.com/150',
      //           quantity: 5,
      //           status: OrderItemStatus.picked,
      //           description: 'Description of Item 5',
      //         ),
      //       ],
      //     ),
      //   ];
      //   emit(PickerOrdersLoaded(sampleOrders));
      // }
    } catch (e) {
      emit(PickerOrdersError(e.toString()));
    }
  }
}
