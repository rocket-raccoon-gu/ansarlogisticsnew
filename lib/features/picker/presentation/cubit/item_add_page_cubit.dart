import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'package:ansarlogisticsnew/features/picker/data/models/order_replacement_product_model.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
// Update the import path as needed

part 'item_add_page_state.dart';

class ItemAddPageCubit extends Cubit<ItemAddPageState> {
  ItemAddPageCubit() : super(ItemAddPageInitial());

  OrderReplacementProductModel? product;

  Future<void> addItem(
    int itemId,
    String scannedSku,
    String reason,
    String price,
    String qty,
    String preparationId,
    int isProduce,
    int productId,
    String productName,
    String orderNumber,
  ) async {
    try {
      if (!isClosed) {
        emit(ItemAddPageLoading());
      }
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.updateItemStatus(
        itemId: itemId,
        scannedSku: scannedSku,
        status: "new",
        price: price,
        qty: qty,
        preparationId: preparationId.toString(),
        isProduce: isProduce,
        token: token!,
        productId: productId,
        productName: productName,
        orderNumber: orderNumber,
      );
      if (response.statusCode == 200) {
        if (!isClosed) {
          emit(ItemAddPageSuccess());
        }
      } else {
        if (!isClosed) {
          emit(ItemAddPageError('Failed to add item'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(ItemAddPageError('An error occurred'));
      }
    }
  }

  void showError(String message) {
    if (!isClosed) {
      emit(ItemAddPageError(message));
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

  Future<void> scanBarcode(String barcode) async {
    if (!isClosed) {
      emit(ItemAddPageLoading());
    }

    try {
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null || token.isEmpty) {
        final errorMessage =
            'Authentication token not found. Please login again.';
        showToast(errorMessage, isError: true);
        if (!isClosed) {
          emit(ItemAddPageError(errorMessage));
        }
        return;
      }

      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.getProductBySku(barcode, token);

      if (response.statusCode == 200) {
        product = OrderReplacementProductModel.fromJson(response.data);
        if (!isClosed) {
          emit(ItemAddPageLoaded(product!));
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
            print('🔍 Barcode scan error response: $responseData');
          }
        } catch (e) {
          print('Error parsing error response: $e');
        }

        // Show error message in toast
        showToast(errorMessage, isError: true);

        // Emit error state
        if (!isClosed) {
          emit(ItemAddPageError(errorMessage));
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

      print('🔍 Barcode scan exception: $e');

      // Show error message in toast
      showToast(errorMessage, isError: true);

      // Emit error state
      if (!isClosed) {
        emit(ItemAddPageError(errorMessage));
      }
    }
  }
}
