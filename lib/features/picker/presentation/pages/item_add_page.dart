import 'dart:developer';

import 'package:ansarlogisticsnew/features/picker/presentation/widgets/barcode_scanner_widget.dart';
import 'package:api_gateway/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/cubit/item_add_page_cubit.dart';

class ItemAddPage extends StatefulWidget {
  final int preparationId;
  const ItemAddPage({super.key, required this.preparationId});

  @override
  State<ItemAddPage> createState() => _ItemAddPageState();
}

class _ItemAddPageState extends State<ItemAddPage> {
  bool _isScanning = false;
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  bool _barcodeFieldFocused = false;
  String? _replacementBarcode;
  int _replacementQuantity = 1;

  @override
  void initState() {
    super.initState();
    _barcodeFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _barcodeFieldFocused = _barcodeFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _barcodeFocusNode.removeListener(_handleFocusChange);
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItemAddPageCubit(),
      child: Scaffold(
        body: BlocConsumer<ItemAddPageCubit, ItemAddPageState>(
          listener: (context, state) {
            if (state is ItemAddPageError) {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is ItemAddPageLoaded) {
              // Navigator.pop(context, 'added');
              Navigator.pop(context);
              _replacementBarcode = state.product.sku;
            } else if (state is ItemAddPageLoading) {
              // Optionally show a loading indicator
              showDialog(
                context: context,
                builder: (context) {
                  return const Center(child: CircularProgressIndicator());
                },
              );
            } else if (state is ItemAddPageSuccess) {
              Navigator.pop(context);
              Navigator.pop(context, 'updated');
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(content: Text('Item added successfully')),
              // );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // if (state is ItemAddPageLoading)
                //   const Positioned(
                //     top: 0,
                //     left: 0,
                //     right: 0,
                //     child: LinearProgressIndicator(),
                //   ),
                if (_isScanning)
                  BarcodeScannerWidget(
                    title: 'Scan Item Barcode',
                    subtitle:
                        'Please scan the barcode of the item you want to add.',
                    onBarcodeScanned: (sku) async {
                      setState(() {
                        _isScanning = false;
                        _replacementBarcode = sku;
                      });
                      await context.read<ItemAddPageCubit>().scanBarcode(sku);
                    },
                  ),
                if (!_isScanning)
                  Scaffold(
                    backgroundColor: Colors.grey[100],
                    appBar: AppBar(
                      title: const Text('Add New Item'),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 1,
                    ),
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add Item by Barcode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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

                                      // Expanded(
                                      //   child: ElevatedButton.icon(
                                      //     onPressed: () {
                                      //       setState(() {
                                      //         _isScanning = true;
                                      //       });
                                      //     },
                                      //     icon: const Icon(
                                      //       Icons.qr_code_scanner,
                                      //     ),
                                      //     label: const Text('Scan Barcode'),
                                      //     style: ElevatedButton.styleFrom(
                                      //       backgroundColor: Colors.blue,
                                      //       foregroundColor: Colors.white,
                                      //       padding: const EdgeInsets.symmetric(
                                      //         vertical: 16,
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  if (state is ItemAddPageLoaded) ...[
                                    Divider(height: 32),
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            getFullImageUrl(
                                              state.product.firstImageUrl,
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
                                                'New Item:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                state.product.skuName ??
                                                    'Unknown Product',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'SKU: ${state.product.sku}',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Price: ${double.parse(state.product.regularPrice).toStringAsFixed(2)} QAR',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                          style: const TextStyle(fontSize: 18),
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
                                        if (state.product.isProduce == '1')
                                          Text(
                                            'Produce Item',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ] else
                                    Column(
                                      children: [
                                        const Text(
                                          'Or enter barcode manually:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        TextField(
                                          focusNode: _barcodeFocusNode,
                                          controller: _barcodeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Enter Barcode',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.edit),
                                          ),
                                          textInputAction: TextInputAction.done,
                                          onChanged: (v) {
                                            setState(
                                              () {},
                                            ); // Rebuild to enable/disable Send button
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_barcodeFieldFocused)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _barcodeController.text.trim().isEmpty
                                        ? null
                                        : () {
                                          // Call API to add item using barcode (manual or scanned)
                                          context
                                              .read<ItemAddPageCubit>()
                                              .scanBarcode(
                                                _barcodeController.text.trim(),
                                              );
                                          _barcodeFocusNode.unfocus();
                                        },
                                icon: const Icon(Icons.send),
                                label: const Text('Send'),
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
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _barcodeFocusNode.requestFocus();

                                      if (state is ItemAddPageLoaded) {
                                        _replacementBarcode = state.product.sku;
                                        context
                                            .read<ItemAddPageCubit>()
                                            .addItem(
                                              0,
                                              _replacementBarcode!,
                                              '',
                                              state.product.regularPrice,
                                              _replacementQuantity.toString(),
                                              widget.preparationId,
                                              state.product.isProduce == '1'
                                                  ? 1
                                                  : 0,
                                              state.product.productId,
                                              state.product.skuName ?? '',
                                            );
                                      } else {
                                        _replacementBarcode =
                                            _barcodeController.text.trim();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Add New Item'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    const baseUrl = ApiConfig.imageUrl;
    log('getFullImageUrl: $baseUrl$path');
    return '$baseUrl$path';
  }
}
