import 'dart:developer';

import 'package:api_gateway/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/item_replacement_page_cubit.dart';
import '../widgets/barcode_scanner_widget.dart';

class ItemReplacementPage extends StatefulWidget {
  final OrderItemModel item;
  final String? barcode;
  final int preparationId;

  const ItemReplacementPage({
    Key? key,
    required this.item,
    this.barcode,
    required this.preparationId,
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

  void _handleManualBarcodeSubmit(BuildContext context) async {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a barcode.')),
      );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Item replaced successfully!')),
            );
            // Pop twice to get back to the item listing page
            Navigator.of(context).pop(); // Pop ItemReplacementPage
            Navigator.of(
              context,
            ).pop('updated'); // Pop OrderItemDetailsPage with result
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
                  BarcodeScannerWidget(
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
                    body: SingleChildScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget.item.productImages.isNotEmpty
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            width: 80,
                                            height: 80,
                                            getFullImageUrl(
                                              widget.item.productImages.first,
                                            ),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      width: 80,
                                                      height: 80,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                        )
                                        : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            getFullImageUrl(
                                              widget.item.imageUrl,
                                            ),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      width: 80,
                                                      height: 80,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
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
                                            style: TextStyle(fontSize: 15),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  _replacementBarcode != null
                                                      ? Colors.black
                                                      : Colors.grey,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.qr_code_scanner),
                                          tooltip: 'Scan Replacement Barcode',
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
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _manualBarcodeController,
                                              decoration: const InputDecoration(
                                                labelText: 'Enter Barcode',
                                                border: InputBorder.none,
                                              ),
                                              style: const TextStyle(fontSize: 16),
                                              onSubmitted: (_) => _handleManualBarcodeSubmit(context),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _handleManualBarcodeSubmit(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Submit'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (state is ItemReplacementLoaded) ...[
                                      Divider(height: 32),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              getFullImageUrl(
                                                state
                                                    .selectedReplacement
                                                    .firstImageUrl,
                                              ),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Replacement Item',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
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
                                                    color: Colors.grey[700],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'Barcode: ${_replacementBarcode ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Text(
                                            'Quantity:',
                                            style: TextStyle(fontSize: 16),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedReason,
                                          hint: Text('Select a reason'),
                                          isExpanded: true,
                                          underline: SizedBox(),
                                          items:
                                              _reasons.map((reason) {
                                                return DropdownMenuItem<String>(
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
                            SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      textStyle: TextStyle(
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
                                                  SnackBar(
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
                                                    widget.item.price
                                                        .toString(),
                                                    _replacementQuantity
                                                        .toString(),
                                                    widget.preparationId,
                                                    widget.item.isProduce
                                                        ? 1
                                                        : 0,
                                                  );
                                            },
                                    child: const Text('Confirm Replacement'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
