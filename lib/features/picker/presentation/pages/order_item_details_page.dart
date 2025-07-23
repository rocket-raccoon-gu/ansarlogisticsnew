import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import 'package:api_gateway/config/api_config.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../widgets/product_found_dialog.dart';
import '../widgets/product_not_matching_dialog.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import '../../../../core/services/user_storage_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/notfound_dialog.dart';
import 'dart:developer';

class OrderItemDetailsPage extends StatefulWidget {
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final int preparationId;
  final OrderModel order;

  const OrderItemDetailsPage({
    super.key,
    required this.item,
    required this.cubit,
    required this.preparationId,
    required this.order,
  });

  @override
  State<OrderItemDetailsPage> createState() => _OrderItemDetailsPageState();
}

class _OrderItemDetailsPageState extends State<OrderItemDetailsPage> {
  late int _quantity;
  bool _isLoading = false;
  bool _isProcessing = false;
  late TextEditingController _manualBarcodeController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _manualBarcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _manualBarcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return BarcodeScannerWidget(
        title: 'Scan Barcode',
        subtitle: 'Scan the barcode for ${widget.item.name}',
        onBarcodeScanned: (barcode) => _handleBarcodeScanned(context, barcode),
      );
    } else {
      return Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text("Item Details")),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Images
                            if (widget.item.productImages.isNotEmpty)
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: widget.item.productImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 180,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          '${ApiConfig.imageUrl}${widget.item.productImages[index]}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.item.imageUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.image,
                                              size: 80,
                                              color: Colors.grey,
                                            ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              widget.item.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    widget.item.deliveryType == 'exp'
                                        ? 'Express'
                                        : 'No Limit',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text('SKU: ${widget.item.sku ?? '-'}'),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'QAR ${widget.item.price?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            if (widget.item.description != null &&
                                widget.item.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  widget.item.description!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  AppStrings.quantity,
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed:
                                      _quantity > 1
                                          ? () {
                                            setState(() {
                                              _quantity--;
                                            });
                                            widget.cubit.updateQuantity(
                                              widget.item,
                                              _quantity,
                                            );
                                          }
                                          : null,
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                    widget.cubit.updateQuantity(
                                      widget.item,
                                      _quantity,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 20),
                    // Section: Pick Item
                    Text(
                      'Pick Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.item.status != OrderItemStatus.picked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan Barcode to Pick'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isProcessing = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    enabled:
                                        widget.item.status !=
                                            OrderItemStatus.picked &&
                                        !_isLoading,
                                    controller: _manualBarcodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter Barcode',
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(fontSize: 16),
                                    onSubmitted:
                                        (value) => _handleManualBarcodeSubmit(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed:
                                      (widget.item.status ==
                                                  OrderItemStatus.picked ||
                                              _isLoading)
                                          ? null
                                          : _handleManualBarcodeSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Submit'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 20),
                    // Section: Other Actions
                    Text(
                      'Other Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text(AppStrings.notAvailable),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                widget.item.status ==
                                        OrderItemStatus.itemNotAvailable
                                    ? null
                                    : () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => ConfirmationDialog(
                                              title: 'Mark as Not Available',
                                              message:
                                                  'Are you sure you want to mark "${widget.item.name}" as not available?',
                                              confirmText: 'Mark Not Available',
                                              confirmColor: Colors.orange,
                                              item: widget.item,
                                              cubit: widget.cubit,
                                              status: 'item_not_available',
                                              reason:
                                                  'Manually marked as not available',
                                            ),
                                      );
                                    },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text(AppStrings.canceled),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey,
                              side: const BorderSide(color: Colors.grey),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                widget.item.status == OrderItemStatus.canceled
                                    ? null
                                    : () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => ConfirmationDialog(
                                              title: 'Cancel Item',
                                              message:
                                                  'Are you sure you want to cancel "${widget.item.name}"?',
                                              confirmText: 'Cancel Item',
                                              confirmColor: Colors.grey,
                                              item: widget.item,
                                              cubit: widget.cubit,
                                              status: 'item_canceled',
                                              reason: 'Manually canceled',
                                            ),
                                      );
                                    },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.pause_circle_outline),
                            label: const Text('Hold'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber,
                              side: const BorderSide(color: Colors.amber),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                widget.item.status == OrderItemStatus.holded
                                    ? null
                                    : () async {
                                      await widget.cubit.updateItemStatus(
                                        item: widget.item,
                                        status: 'holded',
                                        scannedSku: widget.item.sku ?? '',
                                        reason: null,
                                      );
                                      if (mounted) {
                                        Navigator.of(context).pop(
                                          'holded',
                                        ); // Will trigger reload and switch to On Hold tab
                                      }
                                    },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(minHeight: 4),
            ),
        ],
      );
    }
  }

  // void _openScanner(BuildContext context) {
  //   // Show a brief message about scanning
  //   Fluttertoast.showToast(
  //     msg: 'Scanning barcode for: ${widget.item.name}',
  //     toastLength: Toast.LENGTH_SHORT,
  //     gravity: ToastGravity.CENTER,
  //     backgroundColor: Colors.blue,
  //   );

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => BarcodeScannerWidget(
  //             title: 'Scan Barcode',
  //             subtitle: 'Scan the barcode for ${widget.item.name}',
  //             onBarcodeScanned:
  //                 (barcode) => _handleBarcodeScanned(context, barcode),
  //           ),
  //     ),
  //   );
  // }

  String getPriceFromBarcode(String code) {
    String last = code;
    String price = "00";
    if (code.startsWith('00')) {
      last = code.substring(2);
    }
    double parsedValue = double.parse(last) / 1000;
    String priceString = parsedValue.toString();
    int dotIndex = priceString.indexOf('.');
    if (dotIndex != -1 && dotIndex < priceString.length - 2) {
      price = priceString.substring(0, dotIndex + 3);
    } else {
      price = priceString;
    }
    return price;
  }

  Future<void> _handleBarcodeScanned(
    BuildContext context,
    String barcode,
  ) async {
    if (widget.item.isProduce) {
      final dialogContext = context;
      String produceBarcode = barcode
          .substring(0, 6)
          .padRight(barcode.length, '0');
      String price = getPriceFromBarcode(barcode.substring(barcode.length - 7));

      // Close scanner page first
      // if (dialogContext.mounted) {
      //   Navigator.of(
      //     dialogContext,
      //     rootNavigator: true,
      //   ).pop(); // Close scanner screen
      // }
      setState(() => _isProcessing = false);
      setState(() => _isLoading = true);

      try {
        final userData = await UserStorageService.getUserData();
        if (!dialogContext.mounted) {
          setState(() => _isLoading = false);
          return;
        }
        final token = userData?.token;
        if (token == null) throw Exception('No token');

        final apiService = ApiService(HttpClient(), WebSocketClient());
        final response = await apiService.scanBarcodeAndPickItem(
          produceBarcode,
          token,
          widget.item.sku ?? '',
        );

        // if (!dialogContext.mounted) {
        //   setState(() => _isLoading = false);
        //   // return;
        // }
        setState(() => _isLoading = false);

        if (response.data != null && response.data['match'] == "0") {
          // Show confirmation dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (priceDialogContext) {
              return AlertDialog(
                title: Text('Produce Item Found'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Barcode: $produceBarcode'),
                    SizedBox(height: 8),
                    Text('Price: QAR $price'),
                    SizedBox(height: 16),
                    Text('Do you want to pick this produce item?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        priceDialogContext,
                      ).pop(); // Close price dialog
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(priceDialogContext).pop(); // Close dialog

                      if (!dialogContext.mounted) return;

                      setState(() => _isLoading = true);
                      try {
                        final userData = await UserStorageService.getUserData();
                        if (!dialogContext.mounted) {
                          setState(() => _isLoading = false);
                          return;
                        }
                        final token = userData?.token;
                        if (token == null) throw Exception('No token');

                        final success = await widget.cubit.updateItemStatus(
                          item: widget.item,
                          status: 'end_picking',
                          scannedSku: barcode,
                          reason: '',
                          priceOverride: price,
                          isProduceOverride: 1,
                        );

                        if (!dialogContext.mounted) {
                          setState(() => _isLoading = false);
                          return;
                        }
                        setState(() => _isLoading = false);

                        if (success) {
                          Fluttertoast.showToast(
                            msg: 'Produce item picked successfully',
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.green,
                          );
                          // if (dialogContext.mounted) {
                          //   Navigator.of(dialogContext).pop('updated');
                          // }

                          if (mounted) {
                            // Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(
                              'updated',
                            ); // Pop item details page, return to item listing
                          }
                        } else {
                          Fluttertoast.showToast(
                            msg: 'Failed to update produce item status',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                          );
                        }
                      } catch (e) {
                        log('Error during updateItemStatus: $e');
                        setState(() => _isLoading = false);
                        Fluttertoast.showToast(
                          msg: 'Error: ${e.toString()}',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                        );
                      }
                    },
                    child: Text('Confirm'),
                  ),
                ],
              );
            },
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Produce barcode not matching',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        log('Error in barcode processing: $e');
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    try {
      // Show loading indicator
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (context) => const Center(child: CircularProgressIndicator()),
      // );
      setState(() => _isLoading = true);

      // Get user token
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!context.mounted) return;
        // Navigator.pop(context); // Close loading dialog
        setState(() => _isLoading = false);
        // Use Fluttertoast instead of ScaffoldMessenger
        Fluttertoast.showToast(
          msg: 'Authentication token not found',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
        );
        return;
      }

      // Call API to scan barcode and pick item
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.scanBarcodeAndPickItem(
        barcode,
        token,
        widget.item.sku ?? '',
      );

      // Close loading dialog
      if (!context.mounted) return;
      // Navigator.pop(context);

      // Check API response
      if (response.data != null && response.data['match'] == "0") {
        // Close scanner on success
        // Navigator.pop(context);
        setState(() => _isProcessing = false);
        // Show product found dialog with pickup button
        _showProductFoundDialog(context, response.data, widget.preparationId);
      } else if (response.data != null && response.data['match'] == "1") {
        // Close scanner
        // Navigator.pop(context);
        setState(() => _isProcessing = false);

        // Show product not matching dialog with replace button
        _showProductNotMatchingDialog(
          context,
          response.data,
          barcode,
          widget.preparationId,
        );
      } else {
        // Show error message from API but don't close scanner
        final errorMessage = response.data?['message'] ?? 'Failed to pick item';
        // Use Fluttertoast instead of ScaffoldMessenger
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
        );

        // Don't close scanner - let user retry
        // The scanner will automatically resume after 1 second due to the debounce mechanism
      }
    } catch (e) {
      // Close loading dialog
      if (!context.mounted) return;
      Navigator.pop(context);

      // Show error message using Fluttertoast
      Fluttertoast.showToast(
        msg: 'Failed to pick item: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
      );

      // Don't close scanner - let user retry
      // The scanner will automatically resume after 1 second due to the debounce mechanism
    }
  }

  void _handleManualBarcodeSubmit() async {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a barcode',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
      );
      return;
    }
    setState(() => _isLoading = true);
    await _handleBarcodeScanned(context, barcode);
    setState(() => _isLoading = false);
  }

  void _showProductFoundDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
    int preparationId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ProductFoundDialog(
          responseData: responseData,
          item: widget.item,
          cubit: widget.cubit,
          parentContext: context,
          onCancel: () {
            setState(() => _isLoading = false);
          },
          onSuccess: () {
            setState(() => _isLoading = false);
          },
        );
      },
    );
  }

  void _showProductNotMatchingDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
    String barcode,
    int preparationId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ProductNotMatchingDialog(
          responseData: responseData,
          barcode: barcode,
          item: widget.item,
          cubit: widget.cubit,
          preparationId: preparationId,
          order: widget.order, // <-- pass the order here
          onCancel: () {
            setState(() => _isLoading = false);
          },
          onSuccess: () {
            setState(() => _isLoading = false);
          },
        );
      },
    );
  }

  void closeAllDialogs(BuildContext context) {
    while (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
