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
import '../../../../core/widgets/safe_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ansarlogisticsnew/core/widgets/network_image_with_loader.dart';

class OrderItemDetailsPage extends StatefulWidget {
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final String preparationId;
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
  bool _isProcessing = false;
  late TextEditingController _manualBarcodeController;
  int selectedindex = 0; // Track selected image index

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

  // Function to get API data (placeholder - you may need to implement this based on your API structure)
  Future<Map<String, dynamic>> getData() async {
    // This should return your API configuration data
    // For now, returning a placeholder structure
    return {'mediapath': ApiConfig.imageUrl};
  }

  // Function to search item on Google
  Future<void> _searchOnGoogle(String itemName) async {
    final searchUrl = Uri.parse(
      "https://www.google.com/search?q=${Uri.encodeQueryComponent(itemName)}",
    );
    try {
      if (await canLaunchUrl(searchUrl)) {
        final launched = await launchUrl(
          searchUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          Fluttertoast.showToast(
            msg: 'Could not open browser',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'No browser app found',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error opening browser: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
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
      return Scaffold(
        appBar: SafeAppBar(
          title: "Item Details",
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          actions: [
            // Google Search Button
            Padding(
              padding: const EdgeInsets.only(right: 22.0),
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.blue, size: 30),
                onPressed: () => _searchOnGoogle(widget.item.name),
                tooltip: 'Search on Google',
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Product Images Section
                        if (widget.item.productImages.isNotEmpty)
                          Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: FutureBuilder<Map<String, dynamic>>(
                                    future: getData(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        Map<String, dynamic> data =
                                            snapshot.data!;

                                        return SizedBox(
                                          height: 270.0,
                                          width: 270.0,
                                          child: Center(
                                            child: NetworkImageWithLoader(
                                              imageUrl:
                                                  widget
                                                              .item
                                                              .productImages
                                                              .isNotEmpty &&
                                                          selectedindex <
                                                              widget
                                                                  .item
                                                                  .productImages
                                                                  .length &&
                                                          widget
                                                              .item
                                                              .productImages[selectedindex]
                                                              .isNotEmpty
                                                      ? "${data['mediapath']}${widget.item.productImages[selectedindex]}"
                                                      : widget
                                                          .item
                                                          .imageUrl
                                                          .isNotEmpty
                                                      ? "${data['mediapath']}${widget.item.imageUrl}"
                                                      : "",
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return SizedBox(
                                          height: 250.0,
                                          width: 250.0,
                                          child: Center(
                                            child: NetworkImageWithLoader(
                                              imageUrl:
                                                  widget
                                                          .item
                                                          .imageUrl
                                                          .isNotEmpty
                                                      ? "${ApiConfig.imageUrl}${widget.item.imageUrl}"
                                                      : "",
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Divider(color: Colors.grey.shade300),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: SizedBox(
                                    height: 40,
                                    child: FutureBuilder(
                                      future: getData(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          Map<String, dynamic> data =
                                              snapshot.data!;
                                          return ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                widget
                                                    .item
                                                    .productImages
                                                    .length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                    ),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedindex = index;
                                                    });
                                                  },
                                                  child: Container(
                                                    height: 60.0,
                                                    width: 60.0,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          width: 3.0,
                                                          color:
                                                              selectedindex ==
                                                                      index
                                                                  ? Color.fromRGBO(
                                                                    183,
                                                                    214,
                                                                    53,
                                                                    1,
                                                                  )
                                                                  : Colors
                                                                      .transparent,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: NetworkImageWithLoader(
                                                        imageUrl:
                                                            widget
                                                                        .item
                                                                        .productImages
                                                                        .isNotEmpty &&
                                                                    index <
                                                                        widget
                                                                            .item
                                                                            .productImages
                                                                            .length &&
                                                                    widget
                                                                        .item
                                                                        .productImages[index]
                                                                        .isNotEmpty
                                                                ? "${data['mediapath']}${widget.item.productImages[index]}"
                                                                : "",
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        } else {
                                          return ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                widget
                                                    .item
                                                    .productImages
                                                    .length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                    ),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedindex = index;
                                                    });
                                                  },
                                                  child: Container(
                                                    height: 60.0,
                                                    width: 60.0,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          width: 3.0,
                                                          color:
                                                              selectedindex ==
                                                                      index
                                                                  ? Color.fromRGBO(
                                                                    183,
                                                                    214,
                                                                    53,
                                                                    1,
                                                                  )
                                                                  : Colors
                                                                      .transparent,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: NetworkImageWithLoader(
                                                        imageUrl:
                                                            widget
                                                                    .item
                                                                    .imageUrl
                                                                    .isNotEmpty
                                                                ? "${ApiConfig.imageUrl}${widget.item.imageUrl}"
                                                                : "",
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Fallback image if no product images
                        if (widget.item.productImages.isEmpty)
                          Center(
                            child: NetworkImageWithLoader(
                              imageUrl:
                                  widget.item.imageUrl.isNotEmpty
                                      ? "${ApiConfig.imageUrl}${widget.item.imageUrl}"
                                      : "",
                              width: 300,
                              height: 300,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                widget.item.deliveryType == 'exp'
                                    ? 'Express'
                                    : 'Normal',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: const TextStyle(color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('SKU: ${widget.item.sku ?? '-'}'),
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.grey.shade100,
                            ),
                          ],
                        ),
                        if (widget.item.isProduce) ...[
                          Chip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 12,
                                  color: Colors.green[700],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Produce',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green.shade50,
                            side: BorderSide(color: Colors.green.shade200),
                          ),
                        ],
                        Text(
                          'QAR ${widget.item.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Customer Order Quantity Display
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: Colors.blue.shade700,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Order Quantity: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                '${widget.item.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              AppStrings.quantity,
                              style: TextStyle(fontSize: 12),
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
                              style: const TextStyle(fontSize: 16),
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
                                  border: Border.all(color: Colors.green[300]!),
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
                // Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 8),

                // Section: Pick Item - Simplified and faster
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

                if (widget.item.status != OrderItemStatus.picked &&
                    widget.item.status != OrderItemStatus.itemNotAvailable &&
                    widget.item.status != OrderItemStatus.holded)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fast Pickup Button - No loading, direct action
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            _quantity > 0
                                ? Icons.qr_code_scanner
                                : Icons.warning,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            _quantity > 0
                                ? 'Scan Barcode to Pick'
                                : 'Update Quantity First',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _quantity > 0 ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (_quantity > 0) {
                              setState(() {
                                _isProcessing = true;
                              });
                            } else {
                              Fluttertoast.showToast(
                                msg: "Update quantity first",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.orange,
                                textColor: Colors.white,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barcode Input Section - Simplified
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
                            Row(
                              children: [
                                if (_manualBarcodeController.text.isNotEmpty)
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                if (_manualBarcodeController.text.isNotEmpty)
                                  SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    enabled:
                                        widget.item.status !=
                                        OrderItemStatus.picked,
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
                                      setState(() {});
                                    },
                                    onSubmitted:
                                        (value) => _handleManualBarcodeSubmit(),
                                  ),
                                ),
                              ],
                            ),
                            if (_manualBarcodeController.text.isNotEmpty &&
                                _quantity > 0)
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
                                                    OrderItemStatus.picked)
                                                ? null
                                                : _handleManualBarcodeSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                const SizedBox(height: 16),

                // Section: Other Actions - Simplified
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
                                      : () => _showNotAvailableDialog(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Canceled Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 20),
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
                                  widget.item.status == OrderItemStatus.canceled
                                      ? null
                                      : () => _showCancelDialog(),
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
                                  widget.item.status == OrderItemStatus.holded
                                      ? null
                                      : () => _handleHoldAction(),
                            ),
                          ),
                        ],
                      );
                    } else {
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
                                      : () => _showNotAvailableDialog(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, size: 20),
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
                                  widget.item.status == OrderItemStatus.canceled
                                      ? null
                                      : () => _showCancelDialog(),
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
                                  widget.item.status == OrderItemStatus.holded
                                      ? null
                                      : () => _handleHoldAction(),
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
      );
    }
  }

  // Simplified dialog methods
  void _showNotAvailableDialog() {
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
            reason: 'Manually marked as not available',
            quantity: _quantity,
          ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Cancel Item',
            message: 'Are you sure you want to cancel "${widget.item.name}"?',
            confirmText: 'Cancel Item',
            confirmColor: Colors.grey,
            item: widget.item,
            cubit: widget.cubit,
            status: 'canceled',
            reason: 'Manually canceled',
            quantity: _quantity,
          ),
    );
  }

  Future<void> _handleHoldAction() async {
    await widget.cubit.updateItemStatus(
      item: widget.item,
      status: 'holded',
      scannedSku: widget.item.sku ?? '',
      reason: null,
      quantity: _quantity,
      isProduceOverride: widget.item.isProduce ? 1 : 0,
    );
    if (mounted) {
      Navigator.of(context).pop('holded');
    }
  }

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
    await _processBarcode(context, barcode);
  }

  // Simplified barcode processing - no loading states
  Future<void> _processBarcode(BuildContext context, String barcode) async {
    if (widget.item.isProduce) {
      await _handleProduceItemBarcode(context, barcode);
      return;
    }

    try {
      // Get user token
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        if (!context.mounted) return;
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
      final response = await apiService.scanBarcodeAndPickItem(
        barcode,
        token,
        widget.item.sku ?? '',
      );

      if (!context.mounted) return;

      // Check API response
      if (response.data != null && response.data['match'] == "0") {
        // Show product found dialog with pickup button
        _showProductFoundDialog(context, response.data, widget.preparationId);
      } else if (response.data != null && response.data['match'] == "1") {
        // Show product not matching dialog with replace button
        _showProductNotMatchingDialog(
          context,
          response.data,
          barcode,
          widget.preparationId,
        );
      } else {
        // Show error message from API
        final errorMessage = response.data?['message'] ?? 'Failed to pick item';
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      Fluttertoast.showToast(
        msg: 'Failed to pick item: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
      );
    }
  }

  // Simplified produce item handling
  Future<void> _handleProduceItemBarcode(
    BuildContext context,
    String barcode,
  ) async {
    String produceBarcode = barcode
        .substring(0, 6)
        .padRight(barcode.length, '0');
    String price = getPriceFromBarcode(barcode.substring(barcode.length - 7));

    setState(() => _isProcessing = false);

    try {
      final userData = await UserStorageService.getUserData();
      if (!context.mounted) return;

      final token = userData?.token;
      if (token == null) throw Exception('No token');

      log('🔍 Produce item barcode: $produceBarcode');

      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.scanBarcodeAndPickItem(
        produceBarcode,
        token,
        widget.item.sku ?? '',
      );

      if (response.data != null && response.data['match'] == "0") {
        // Handle price from API response
        String displayPrice = price;
        String apiPrice = price;

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
              title: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Produce Item Found',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Barcode: $produceBarcode'),
                  SizedBox(height: 8),
                  Text('Price: QAR $displayPrice'),
                  SizedBox(height: 16),
                  Text('Do you want to pick this produce item?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(priceDialogContext).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(priceDialogContext).pop();

                    if (!context.mounted) return;

                    try {
                      final success = await widget.cubit.updateItemStatus(
                        item: widget.item,
                        status: 'end_picking',
                        scannedSku: barcode,
                        reason: '',
                        priceOverride: apiPrice,
                        isProduceOverride: 1,
                        quantity: _quantity,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        Fluttertoast.showToast(
                          msg: 'Produce item picked successfully',
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.green,
                        );

                        if (mounted) {
                          Navigator.of(context).pop('updated');
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
      log('Error in produce barcode processing: $e');
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
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

    // Use the same process for manual barcode submission
    await _processBarcode(context, barcode);
  }

  void _showProductFoundDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
    String preparationId,
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
            // No loading state needed
          },
          onSuccess: () {
            // Navigate back to item listing page
            if (mounted) {
              Navigator.of(context).pop('updated');
            }
          },
          quantity: _quantity,
        );
      },
    );
  }

  void _showProductNotMatchingDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
    String barcode,
    String preparationId,
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
          order: widget.order,
          onCancel: () {
            // No loading state needed
          },
          onSuccess: () {
            // Navigate back to item listing page
            if (mounted) {
              Navigator.of(context).pop('updated');
            }
          },
        );
      },
    );
  }
}
