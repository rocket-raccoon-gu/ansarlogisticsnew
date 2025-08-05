import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'package:ansarlogisticsnew/features/picker/data/models/order_replacement_product_model.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> scanBarcode(String barcode) async {
    if (!isClosed) {
      emit(ItemAddPageLoading());
    }
    final userData = await UserStorageService.getUserData();
    final token = userData?.token;
    final apiService = ApiService(HttpClient(), WebSocketClient());
    final response = await apiService.getProductBySku(barcode, token ?? '');

    if (response.statusCode == 200) {
      product = OrderReplacementProductModel.fromJson(response.data);
      if (!isClosed) {
        emit(ItemAddPageLoaded(product!));
      }
    } else if (response.statusCode == 404) {
      if (!isClosed) {
        emit(ItemAddPageError('Product not found'));
      }
    } else if (response.statusCode == 400) {
      if (!isClosed) {
        emit(ItemAddPageError('Invalid barcode format'));
      }
    } else if (response.statusCode == 500) {
      if (!isClosed) {
        emit(ItemAddPageError('Server error, please try again later'));
      }
    } else {
      if (!isClosed) {
        emit(ItemAddPageError('Unexpected error occurred'));
      }
    }
  }
}
