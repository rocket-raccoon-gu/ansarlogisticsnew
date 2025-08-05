import 'dart:developer';

import 'package:api_gateway/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/item_replacement_page_cubit.dart';
import '../widgets/stable_scanner_widget.dart';
import '../cubit/order_details_cubit.dart';
import 'order_details_page.dart';
import '../../data/models/order_model.dart';
import 'package:ansarlogisticsnew/features/navigation/presentation/pages/main_navigation_page.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/cubit/picker_orders_cubit.dart';
import 'package:ansarlogisticsnew/core/widgets/network_image_with_loader.dart';

class ItemReplacementPage extends StatefulWidget {
  final OrderItemModel item;
  final String? barcode;
  final String preparationId;
  final OrderDetailsCubit orderDetailsCubit;
  final OrderModel order;

  const ItemReplacementPage({
    Key? key,
    required this.item,
    this.barcode,
    required this.preparationId,
    required this.orderDetailsCubit,
    required this.order,
  }) : super(key: key);

  @override
  State<ItemReplacementPage> createState() => _ItemReplacementPageState();
}

class _ItemReplacementPageState extends State<ItemReplacementPage> {
  String? _replacementBarcode;
  bool _isScanning = false;
  int _replacementQuantity = 1;
  String? _selectedReason;

  final List<String> _reasons = [
    'Item Out Of Stock',
    'Item Replacement From Customer Suggestion',
  ];

  late TextEditingController _manualBarcodeController;

  @override
  void initState() {
    super.initState();
    _manualBarcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _manualBarcodeController.dispose();
    super.dispose();
  }

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    const baseUrl = ApiConfig.imageUrl;
    log('getFullImageUrl: $baseUrl$path');
    return '$baseUrl$path';
  }

  String _getDisplayPrice(dynamic replacementProduct) {
    // Priority: current_promotion_price > special_price > regular_price
    // if (replacementProduct.currentPromotionPrice != null &&
    //     replacementProduct.currentPromotionPrice.toString() != 'null' &&
    //     replacementProduct.currentPromotionPrice.toString().isNotEmpty) {
    //   return double.parse(
    //     replacementProduct.currentPromotionPrice.toString(),
    //   ).toStringAsFixed(2);
    // }
    if (replacementProduct.specialPrice != null &&
        replacementProduct.specialPrice.toString() != 'null' &&
        replacementProduct.specialPrice.toString().isNotEmpty) {
      return double.parse(
        replacementProduct.specialPrice.toString(),
      ).toStringAsFixed(2);
    } else {
      return double.parse(
        replacementProduct.regularPrice.toString(),
      ).toStringAsFixed(2);
    }
  }

  void _handleManualBarcodeSubmit(BuildContext context) async {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a barcode.')));
      return;
    }
    setState(() {
      _replacementBarcode = barcode;
    });
    context.read<ItemReplacementCubit>().getProductBySku(barcode);
    // Unfocus the text field to dismiss the keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItemReplacementCubit(),
      child: BlocListener<ItemReplacementCubit, ItemReplacementState>(
        listener: (context, state) {
          if (state is ItemReplacementSuccess) {
            // First, reload items in the orderDetailsCubit before navigation
            widget.orderDetailsCubit.reloadItemsFromApi();

            // Then navigate to OrderDetailsPage and reload items
            // First, navigate to MainNavigationPage (Picker Orders)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder:
                    (context) => BlocProvider(
                      create: (_) => PickerOrdersCubit(),
                      child: const MainNavigationPage(),
                    ),
              ),
              (route) => false, // Remove all previous routes
            );

            // Then navigate to OrderDetailsPage from the MainNavigationPage
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => OrderDetailsPage(
                        order: widget.order,
                        existingCubit: widget.orderDetailsCubit,
                      ),
                ),
              );
            });
          }
          if (state is ItemReplacementError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to replace item.')));
          }
        },
        child: BlocBuilder<ItemReplacementCubit, ItemReplacementState>(
          builder: (context, state) {
            return Stack(
              children: [
                if (_isScanning)
                  StableScannerWidget(
                    title: 'Scan Replacement Barcode',
                    subtitle: 'Scan the barcode for the replacement item',
                    onBarcodeScanned: (barcode) async {
                      setState(() {
                        _replacementBarcode = barcode;
                        _isScanning = false;
                      });
                      context.read<ItemReplacementCubit>().getProductBySku(
                        barcode,
                      );
                    },
                  ),
                if (!_isScanning)
                  Scaffold(
                    backgroundColor: Colors.grey[100],
                    appBar: AppBar(
                      title: Text('Item Replacement'),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 1,
                    ),
                    body: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          widget.item.productImages.isNotEmpty
                                              ? NetworkImageWithLoader(
                                                imageUrl: getFullImageUrl(
                                                  widget
                                                      .item
                                                      .productImages
                                                      .first,
                                                ),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              )
                                              : NetworkImageWithLoader(
                                                imageUrl: getFullImageUrl(
                                                  widget.item.imageUrl,
                                                ),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Original Item',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  widget.item.name,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  'SKU: ${widget.item.sku ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (widget.barcode != null)
                                                  Text(
                                                    'Scanned Barcode: ${widget.barcode}',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                SizedBox(height: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.red[200]!,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Price: QAR ${widget.item.price?.toStringAsFixed(2) ?? '0.00'}',
                                                    style: TextStyle(
                                                      color: Colors.red[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 18),
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Replacement Barcode',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _replacementBarcode ??
                                                      'No barcode scanned',
                                                  style: TextStyle(
                                                    color:
                                                        _replacementBarcode !=
                                                                null
                                                            ? Colors.black
                                                            : Colors.grey,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.qr_code_scanner,
                                                ),
                                                tooltip:
                                                    'Scan Replacement Barcode',
                                                onPressed: () {
                                                  setState(() {
                                                    _isScanning = true;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          // Manual barcode entry
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _manualBarcodeController,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Enter Barcode',
                                                          border:
                                                              InputBorder.none,
                                                        ),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                    onSubmitted:
                                                        (_) =>
                                                            _handleManualBarcodeSubmit(
                                                              context,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed:
                                                      () =>
                                                          _handleManualBarcodeSubmit(
                                                            context,
                                                          ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 18,
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text('Submit'),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          if (state
                                              is ItemReplacementLoaded) ...[
                                            Divider(height: 32),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                NetworkImageWithLoader(
                                                  imageUrl: getFullImageUrl(
                                                    state
                                                        .selectedReplacement
                                                        .firstImageUrl,
                                                  ),
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Replacement Item',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        state
                                                            .selectedReplacement
                                                            .skuName,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        'SKU: ${state.selectedReplacement.sku}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Barcode: ${_replacementBarcode ?? ''}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.green[50],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                Colors
                                                                    .green[200]!,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Price: QAR ${_getDisplayPrice(state.selectedReplacement)}',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .green[700],
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            // Price Comparison Section
                                            Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.blue[200]!,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Price Comparison',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Original',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                            Text(
                                                              'QAR ${widget.item.price?.toStringAsFixed(2) ?? '0.00'}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .red[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color: Colors.blue[600],
                                                        size: 20,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              'Replacement',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                            Text(
                                                              'QAR ${_getDisplayPrice(state.selectedReplacement)}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .green[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Quantity:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                  onPressed:
                                                      _replacementQuantity > 1
                                                          ? () {
                                                            setState(() {
                                                              _replacementQuantity--;
                                                            });
                                                          }
                                                          : null,
                                                ),
                                                Text(
                                                  '$_replacementQuantity',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _replacementQuantity++;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Replacement Reason',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButton<String>(
                                                value: _selectedReason,
                                                hint: Text('Select a reason'),
                                                isExpanded: true,
                                                underline: SizedBox(),
                                                items:
                                                    _reasons.map((reason) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: reason,
                                                        child: Text(reason),
                                                      );
                                                    }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedReason = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Total Cost Summary
                                  if (state is ItemReplacementLoaded) ...[
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Replacement Summary',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Original Total:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'QAR ${(widget.item.price ?? 0) * _replacementQuantity}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Replacement Total:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'QAR ${(double.tryParse(_getDisplayPrice(state.selectedReplacement)) ?? 0) * _replacementQuantity}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Price Difference:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                              Text(
                                                'QAR ${((double.tryParse(_getDisplayPrice(state.selectedReplacement)) ?? 0) - (widget.item.price ?? 0)) * _replacementQuantity}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Fixed bottom buttons
                              //   Container(
                              //     padding: const EdgeInsets.all(16.0),
                              //     decoration: BoxDecoration(
                              //       color: Colors.white,
                              //       boxShadow: [
                              //         BoxShadow(
                              //           color: Colors.black.withOpacity(0.1),
                              //           blurRadius: 4,
                              //           offset: const Offset(0, -2),
                              //         ),
                              //       ],
                              //     ),
                              //     child: Row(
                              //       children: [
                              //         Expanded(
                              //           child: OutlinedButton(
                              //             onPressed: () => Navigator.of(context).pop(),
                              //             style: OutlinedButton.styleFrom(
                              //               foregroundColor: Colors.red,
                              //               side: BorderSide(color: Colors.red),
                              //               padding: const EdgeInsets.symmetric(vertical: 16),
                              //             ),
                              //             child: const Text(
                              //               'Cancel',
                              //               style: TextStyle(
                              //                 fontSize: 16,
                              //                 fontWeight: FontWeight.bold,
                              //               ),
                              //             ),
                              //           ),
                              //         ),
                              //         const SizedBox(width: 12),
                              //         Expanded(
                              //           child: ElevatedButton(
                              //             style: ElevatedButton.styleFrom(
                              //               backgroundColor: Colors.green,
                              //               foregroundColor: Colors.white,
                              //               padding: const EdgeInsets.symmetric(vertical: 16),
                              //               textStyle: const TextStyle(
                              //                 fontSize: 16,
                              //                 fontWeight: FontWeight.bold,
                              //               ),
                              //             ),
                              //             onPressed: state is ItemReplacementLoading ||
                              //                     !(state is ItemReplacementLoaded &&
                              //                         _replacementBarcode != null)
                              //                 ? null
                              //                 : () {
                              //                     if (_selectedReason == null) {
                              //                       ScaffoldMessenger.of(context).showSnackBar(
                              //                         const SnackBar(
                              //                           content: Text(
                              //                             'Please select a reason.',
                              //                           ),
                              //                         ),
                              //                       );
                              //                       return;
                              //                     }
                              //                     context
                              //                         .read<ItemReplacementCubit>()
                              //                         .confirmReplacement(
                              //                           int.parse(widget.item.id),
                              //                           _replacementBarcode ?? '',
                              //                           _selectedReason ?? '',
                              //                           state.selectedReplacement.regularPrice
                              //                               .toString(),
                              //                           _replacementQuantity.toString(),
                              //                           widget.preparationId,
                              //                           state.selectedReplacement.isProduce == '1'
                              //                               ? 1
                              //                               : 0,
                              //                           widget.item.subgroupIdentifier ?? '',
                              //                           state.selectedReplacement.skuName,
                              //                           widget.orderDetailsCubit,
                              //                         );
                              //                   },
                              //             child: Text(
                              //               state is ItemReplacementLoaded
                              //                   ? 'Confirm Replacement (QAR ${_getDisplayPrice(state.selectedReplacement)})'
                              //                   : 'Confirm Replacement',
                              //             ),
                              //           ),
                              //         ),
                              //       ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed:
                                      state is ItemReplacementLoading ||
                                              !(state is ItemReplacementLoaded &&
                                                  _replacementBarcode != null)
                                          ? null
                                          : () {
                                            if (_selectedReason == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please select a reason.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            context
                                                .read<ItemReplacementCubit>()
                                                .confirmReplacement(
                                                  int.parse(widget.item.id),
                                                  _replacementBarcode ?? '',
                                                  _selectedReason ?? '',
                                                  state
                                                      .selectedReplacement
                                                      .regularPrice
                                                      .toString(),
                                                  _replacementQuantity
                                                      .toString(),
                                                  widget.preparationId,
                                                  state
                                                              .selectedReplacement
                                                              .isProduce ==
                                                          '1'
                                                      ? 1
                                                      : 0,
                                                  widget
                                                          .item
                                                          .subgroupIdentifier ??
                                                      '',
                                                  state
                                                      .selectedReplacement
                                                      .skuName,
                                                  widget.orderDetailsCubit,
                                                );
                                          },
                                  child: Text(
                                    state is ItemReplacementLoaded
                                        ? 'Confirm'
                                        : 'Confirm ',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state is ItemReplacementLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
