import 'package:ansarlogisticsnew/features/picker/data/models/order_item_model.dart';
import 'package:ansarlogisticsnew/features/picker/data/models/order_replacement_product_model.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/services/user_storage_service.dart';
import 'order_details_cubit.dart';

part 'item_replacement_state.dart';

class ItemReplacementCubit extends Cubit<ItemReplacementState> {
  ItemReplacementCubit() : super(ItemReplacementInitial());

  void selectReplacement(OrderReplacementProductModel item) {
    if (!isClosed) {
      emit(ItemReplacementLoaded(selectedReplacement: item));
    }
  }

  // Method to show toast messages
  void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> getProductBySku(String sku) async {
    try {
      if (!isClosed) {
        emit(ItemReplacementLoading());
      }

      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null || token.isEmpty) {
        final errorMessage =
            'Authentication token not found. Please login again.';
        showToast(errorMessage, isError: true);
        if (!isClosed) {
          emit(ItemReplacementError());
        }
        return;
      }

      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.getProductBySku(sku, token);

      if (response.statusCode == 200) {
        final product = OrderReplacementProductModel.fromJson(response.data);
        if (!isClosed) {
          emit(ItemReplacementLoaded(selectedReplacement: product));
        }
      } else {
        // Handle error response with message from API
        String errorMessage = 'An error occurred';

        try {
          // Try to extract error message from response data
          if (response.data != null && response.data is Map<String, dynamic>) {
            final responseData = response.data as Map<String, dynamic>;

            // Check for message field in the response
            if (responseData.containsKey('message')) {
              errorMessage = responseData['message'] ?? errorMessage;
            }

            // Check for suggestion field and append it if available
            if (responseData.containsKey('suggestion')) {
              final suggestion = responseData['suggestion'];
              if (suggestion != null && suggestion.isNotEmpty) {
                errorMessage += '\n\nSuggestion: $suggestion';
              }
            }

            // Log the full error response for debugging
            print(
              '🔍 Item replacement barcode scan error response: $responseData',
            );
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }

        // Show error message in toast
        showToast(errorMessage, isError: true);

        if (!isClosed) {
          emit(ItemReplacementError());
        }
      }
    } catch (e) {
      // Handle network errors and other exceptions
      String errorMessage =
          'Network error occurred. Please check your connection and try again.';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response format from server.';
      } else if (e.toString().contains('Exception')) {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }

      print('🔍 Item replacement barcode scan exception: $e');

      // Show error message in toast
      showToast(errorMessage, isError: true);

      if (!isClosed) {
        emit(ItemReplacementError());
      }
    }
  }

  Future<void> confirmReplacement(
    int itemId,
    String scannedSku,
    String reason,
    String price,
    String qty,
    String preparationId,
    int isProduce,
    String orderNumber,
    String productName,
    OrderDetailsCubit? orderDetailsCubit, // <-- add this parameter
  ) async {
    try {
      if (!isClosed) {
        emit(ItemReplacementLoading());
      }
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.updateItemStatus(
        itemId: itemId,
        scannedSku: scannedSku,
        status: "replaced",
        price: price,
        qty: qty,
        preparationId: preparationId.toString(),
        isProduce: isProduce,
        token: token ?? '',
        reason: reason,
        orderNumber: orderNumber,
        productName: productName,
      );
      if (response.statusCode == 200) {
        // Update statuses in OrderDetailsCubit if barcodes are present
        final data = response.data;
        if (orderDetailsCubit != null && data != null) {
          final notAvailableBarcode = data['item_not_available'];
          final pickedBarcode = data['end_picking'];
          orderDetailsCubit.updateItemStatusByBarcode(
            notAvailableBarcode: notAvailableBarcode,
            pickedBarcode: pickedBarcode,
          );
        }

        // Check if cubit is still active before emitting
        if (!isClosed) {
          emit(ItemReplacementSuccess());
        }
      } else {
        if (!isClosed) {
          emit(ItemReplacementError());
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(ItemReplacementError());
      }
    }
  }
}
