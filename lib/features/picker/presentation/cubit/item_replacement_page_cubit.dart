import 'package:ansarlogisticsnew/features/picker/data/models/order_item_model.dart';
import 'package:ansarlogisticsnew/features/picker/data/models/order_replacement_product_model.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/user_storage_service.dart';
import 'order_details_cubit.dart';

part 'item_replacement_state.dart';

class ItemReplacementCubit extends Cubit<ItemReplacementState> {
  ItemReplacementCubit() : super(ItemReplacementInitial());

  void selectReplacement(OrderReplacementProductModel item) {
    emit(ItemReplacementLoaded(selectedReplacement: item));
  }

  Future<void> getProductBySku(String sku) async {
    try {
      emit(ItemReplacementLoading());
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.getProductBySku(sku, token ?? '');
      if (response.statusCode == 200) {
        final product = OrderReplacementProductModel.fromJson(response.data);
        emit(ItemReplacementLoaded(selectedReplacement: product));
      } else {
        emit(ItemReplacementError());
      }
    } catch (e) {
      emit(ItemReplacementError());
    }
  }

  Future<void> confirmReplacement(
    int itemId,
    String scannedSku,
    String reason,
    String price,
    String qty,
    int preparationId,
    int isProduce,
    String orderNumber,
    String productName,
    OrderDetailsCubit? orderDetailsCubit, // <-- add this parameter
  ) async {
    try {
      emit(ItemReplacementLoading());
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.updateItemStatus(
        itemId: itemId,
        scannedSku: scannedSku,
        status: "replaced",
        price: price,
        qty: qty,
        preparationId: preparationId,
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
        emit(ItemReplacementSuccess());
      } else {
        emit(ItemReplacementError());
      }
    } catch (e) {
      emit(ItemReplacementError());
    }
  }
}
