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
    int preparationId,
    int isProduce,
    int productId,
    String productName,
  ) async {
    try {
      emit(ItemAddPageLoading());
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.updateItemStatus(
        itemId: itemId,
        scannedSku: scannedSku,
        status: "new",
        price: price,
        qty: qty,
        preparationId: preparationId,
        isProduce: isProduce,
        token: token!,
        productId: productId,
        productName: productName,
      );
      if (response.statusCode == 200) {
        emit(ItemAddPageSuccess());
      } else {
        emit(ItemAddPageError('Failed to add item'));
      }
    } catch (e) {
      emit(ItemAddPageError('An error occurred'));
    }
  }

  void showError(String message) {
    emit(ItemAddPageError(message));
  }

  Future<void> scanBarcode(String barcode) async {
    emit(ItemAddPageLoading());
    final userData = await UserStorageService.getUserData();
    final token = userData?.token;
    final apiService = ApiService(HttpClient(), WebSocketClient());
    final response = await apiService.getProductBySku(barcode, token ?? '');

    if (response.statusCode == 200) {
      product = OrderReplacementProductModel.fromJson(response.data);
      emit(ItemAddPageLoaded(product!));
    } else if (response.statusCode == 404) {
      emit(ItemAddPageError('Product not found'));
    } else if (response.statusCode == 400) {
      emit(ItemAddPageError('Invalid barcode format'));
    } else if (response.statusCode == 500) {
      emit(ItemAddPageError('Server error, please try again later'));
    } else {
      emit(ItemAddPageError('Unexpected error occurred'));
    }
  }
}
