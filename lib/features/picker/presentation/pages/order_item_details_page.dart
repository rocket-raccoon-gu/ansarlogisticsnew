import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import 'package:api_gateway/config/api_config.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../widgets/optimized_barcode_scanner_widget.dart';
import '../widgets/simple_barcode_scanner_widget.dart';
import '../widgets/test_scanner_widget.dart';
import '../widgets/minimal_scanner_widget.dart';
import '../widgets/debug_scanner_widget.dart';
import '../widgets/production_scanner_widget.dart';
import '../widgets/stable_scanner_widget.dart';
import '../widgets/product_found_dialog.dart';
import '../widgets/product_not_matching_dialog.dart';
import '../widgets/improved_product_dialog.dart';
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
import '../../../../core/services/barcode_scanner_service.dart';
import '../../../../core/di/injector.dart';

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
    _quantity = 0; // Initialize to 0 as requested
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
      return StableScannerWidget(
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
                            // Product Images - Made more responsive
                            if (widget.item.productImages.isNotEmpty)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final imageHeight =
                                      constraints.maxWidth < 400
                                          ? 140.0
                                          : 180.0;
                                  final imageWidth =
                                      constraints.maxWidth < 400
                                          ? 140.0
                                          : 180.0;

                                  return SizedBox(
                                    height: imageHeight,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          widget.item.productImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: imageWidth,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              '${ApiConfig.imageUrl}${widget.item.productImages[index]}',
                                              width: imageWidth,
                                              height: imageHeight,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: imageWidth,
                                                  height: imageHeight,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    size: 36,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: imageWidth,
                                                  height: imageHeight,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            // Fallback image if no product images
                            if (widget.item.productImages.isEmpty)
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
                                        : 'Normal Local',
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
                                // Quantity update indicator
                                if (_quantity > 0) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green[700],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Updated',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                    if (widget.item.status == OrderItemStatus.picked)
                      Text(
                        'Picked Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    if (widget.item.status == OrderItemStatus.itemNotAvailable)
                      Text(
                        'Item Not Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    if (widget.item.status == OrderItemStatus.holded)
                      Text(
                        'Holded Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (widget.item.status != OrderItemStatus.picked &&
                        widget.item.status !=
                            OrderItemStatus.itemNotAvailable &&
                        widget.item.status != OrderItemStatus.holded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    _quantity > 0
                                        ? Icons.qr_code_scanner
                                        : Icons.warning,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _quantity > 0
                                        ? 'Scan Barcode to Pick'
                                        : 'Update Quantity First',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _quantity > 0
                                            ? Colors.green
                                            : Colors.orange,
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
                                    // Check if quantity is updated
                                    if (_quantity > 0) {
                                      // Quantity has been updated, allow scanning
                                      setState(() {
                                        _isProcessing = true;
                                      });
                                    } else {
                                      // Show toast message that quantity needs to be updated
                                      Fluttertoast.showToast(
                                        msg: "update quantity first",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.BOTTOM,
                                        backgroundColor: Colors.orange,
                                        textColor: Colors.white,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Barcode Input Section - Made more responsive
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  _manualBarcodeController.text.isNotEmpty
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  _manualBarcodeController.text.isNotEmpty
                                      ? Border.all(
                                        color: Colors.green.shade200,
                                        width: 2,
                                      )
                                      : null,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Barcode input row
                                Row(
                                  children: [
                                    if (_manualBarcodeController
                                        .text
                                        .isNotEmpty)
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    if (_manualBarcodeController
                                        .text
                                        .isNotEmpty)
                                      SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        enabled:
                                            widget.item.status !=
                                                OrderItemStatus.picked &&
                                            !_isLoading,
                                        controller: _manualBarcodeController,
                                        decoration: InputDecoration(
                                          labelText:
                                              _manualBarcodeController
                                                      .text
                                                      .isNotEmpty
                                                  ? 'Scanned Barcode'
                                                  : 'Enter Barcode',
                                          border: InputBorder.none,
                                          labelStyle: TextStyle(
                                            color:
                                                _manualBarcodeController
                                                        .text
                                                        .isNotEmpty
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily:
                                              _manualBarcodeController
                                                      .text
                                                      .isNotEmpty
                                                  ? 'monospace'
                                                  : null,
                                          fontWeight:
                                              _manualBarcodeController
                                                      .text
                                                      .isNotEmpty
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            // Trigger rebuild to update UI
                                          });
                                        },
                                        onSubmitted:
                                            (value) =>
                                                _handleManualBarcodeSubmit(),
                                      ),
                                    ),
                                  ],
                                ),
                                // Action buttons row - responsive layout
                                if (_manualBarcodeController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _manualBarcodeController.clear();
                                            });
                                          },
                                          icon: Icon(
                                            Icons.clear,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Clear barcode',
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed:
                                                (widget.item.status ==
                                                            OrderItemStatus
                                                                .picked ||
                                                        _isLoading)
                                                    ? null
                                                    : _handleManualBarcodeSubmit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Submit Scanned',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                    // Other Actions - Made responsive for smaller screens
                    Text(
                      'Other Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Responsive action buttons layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Use column layout for smaller screens, row for larger screens
                        if (constraints.maxWidth < 600) {
                          return Column(
                            children: [
                              // Not Available Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  label: Text(
                                    AppStrings.notAvailable,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
                                                  (
                                                    context,
                                                  ) => ConfirmationDialog(
                                                    title:
                                                        'Mark as Not Available',
                                                    message:
                                                        'Are you sure you want to mark "${widget.item.name}" as not available?',
                                                    confirmText:
                                                        'Mark Not Available',
                                                    confirmColor: Colors.orange,
                                                    item: widget.item,
                                                    cubit: widget.cubit,
                                                    status:
                                                        'item_not_available',
                                                    reason:
                                                        'Manually marked as not available',
                                                  ),
                                            );
                                          },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Canceled Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 20,
                                  ),
                                  label: Text(
                                    AppStrings.canceled,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: const BorderSide(color: Colors.grey),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed:
                                      widget.item.status ==
                                              OrderItemStatus.canceled
                                          ? null
                                          : () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (
                                                    context,
                                                  ) => ConfirmationDialog(
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
                              const SizedBox(height: 12),
                              // Hold Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.pause_circle_outline,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Hold',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.amber,
                                    side: const BorderSide(color: Colors.amber),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed:
                                      widget.item.status ==
                                              OrderItemStatus.holded
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
                          );
                        } else {
                          // Horizontal layout for larger screens
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  label: Text(
                                    AppStrings.notAvailable,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                                                  (
                                                    context,
                                                  ) => ConfirmationDialog(
                                                    title:
                                                        'Mark as Not Available',
                                                    message:
                                                        'Are you sure you want to mark "${widget.item.name}" as not available?',
                                                    confirmText:
                                                        'Mark Not Available',
                                                    confirmColor: Colors.orange,
                                                    item: widget.item,
                                                    cubit: widget.cubit,
                                                    status:
                                                        'item_not_available',
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
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 20,
                                  ),
                                  label: Text(
                                    AppStrings.canceled,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: const BorderSide(color: Colors.grey),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed:
                                      widget.item.status ==
                                              OrderItemStatus.canceled
                                          ? null
                                          : () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (
                                                    context,
                                                  ) => ConfirmationDialog(
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
                                  icon: const Icon(
                                    Icons.pause_circle_outline,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Hold',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.amber,
                                    side: const BorderSide(color: Colors.amber),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed:
                                      widget.item.status ==
                                              OrderItemStatus.holded
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
                          );
                        }
                      },
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

  void _handleBarcodeScanned(BuildContext context, String barcode) async {
    if (!mounted) return;

    setState(() => _isProcessing = false);

    // Direct API call after barcode scan - no separate submit button needed
    await _processBarcodeImproved(context, barcode);
  }

  Future<void> _processBarcodeImproved(
    BuildContext context,
    String barcode,
  ) async {
    try {
      setState(() => _isLoading = true);

      // Get user token
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!context.mounted) return;
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Authentication token not found',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
        );
        return;
      }

      // Call API to scan barcode and get product information
      final apiService = ApiService(HttpClient(), WebSocketClient());
      log(
        '🔍 Calling scanBarcodeAndPickItem with barcode: $barcode, token: ${token.substring(0, 10)}..., expected SKU: ${widget.item.sku}',
      );

      final response = await apiService.scanBarcodeAndPickItem(
        barcode,
        token,
        widget.item.sku ?? '',
      );

      log('🔍 API Response received: ${response.data}');
      log('🔍 Response statusCode: ${response.statusCode}');

      if (!context.mounted) return;
      setState(() => _isLoading = false);

      // Show the improved product dialog with all the information
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => ImprovedProductDialog(
              responseData: response.data ?? {},
              item: widget.item,
              cubit: widget.cubit,
              parentContext: context,
              barcode: barcode,
              preparationId: widget.preparationId,
              order: widget.order,
              onCancel: () {
                setState(() => _isLoading = false);
              },
              onSuccess: () {
                setState(() => _isLoading = false);
                // Navigate back to item listing page
                if (mounted) {
                  Navigator.of(context).pop('updated');
                }
              },
            ),
      );
    } catch (e) {
      log('Error in improved barcode processing: $e');
      if (!context.mounted) return;
      setState(() => _isLoading = false);

      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
      );
    }
  }

  void _showScannedBarcodeDialog(BuildContext context, String scannedBarcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.green),
              SizedBox(width: 8),
              Text('Barcode Scanned'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barcode scanned successfully!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                'Scanned Code:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  scannedBarcode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'You can edit the barcode in the text field below before submitting.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Clear the text field if user cancels
                setState(() {
                  _manualBarcodeController.clear();
                });
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // The barcode is already in the text field, user can edit and submit
                // Focus on the text field for easy editing
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(Duration(milliseconds: 100), () {
                  FocusScope.of(context).requestFocus(FocusNode());
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBarcode(BuildContext context, String barcode) async {
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
          // Handle price from API response - check for final_price first
          String displayPrice = price; // Default to extracted price
          String apiPrice = price; // Default for API call

          // Check if API response has price information
          if (response.data['final_price'] != null &&
              response.data['final_price'].toString().isNotEmpty &&
              response.data['final_price'].toString() != "0.0000") {
            apiPrice = response.data['final_price'].toString();
            displayPrice = apiPrice;
          } else if (response.data['price'] != null &&
              response.data['price'].toString().isNotEmpty) {
            apiPrice = response.data['price'].toString();
            displayPrice = apiPrice;
          }

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
                    Text('Price: QAR $displayPrice'),
                    if (response.data['final_price'] != null &&
                        response.data['price'] != null &&
                        response.data['final_price'].toString() !=
                            "0.0000") ...[
                      SizedBox(height: 4),
                      Text(
                        'Base Price: QAR ${response.data['price']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Final Price: QAR ${response.data['final_price']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ] else if (response.data['final_price'] != null &&
                        response.data['final_price'].toString() == "0.0000" &&
                        response.data['price'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Using Base Price (Final Price is 0)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
                          priceOverride:
                              apiPrice, // Use the correct price from API
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

    // Use the same improved process for manual barcode submission
    await _processBarcodeImproved(context, barcode);
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
