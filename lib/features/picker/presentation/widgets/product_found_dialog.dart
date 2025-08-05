import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';

class ProductFoundDialog extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final VoidCallback? onSuccess;
  final BuildContext parentContext;
  final VoidCallback? onCancel;
  final int quantity;
  const ProductFoundDialog({
    Key? key,
    required this.responseData,
    required this.item,
    required this.cubit,
    required this.parentContext,
    this.onSuccess,
    this.onCancel,
    required this.quantity,
  }) : super(key: key);

  @override
  State<ProductFoundDialog> createState() => _ProductFoundDialogState();
}

class _ProductFoundDialogState extends State<ProductFoundDialog> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isProcessing,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Product Found'),
          ],
        ),
        content:
            isProcessing
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Updating item status...'),
                  ],
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product found in database with barcode:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Barcode:  ${widget.responseData['sku'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (widget.responseData['product_name'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Product: ${widget.responseData['product_name']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                    // Handle price display - check for final_price first
                    if (widget.responseData['regular_price'] != null ||
                        widget.responseData['current_promotion_price'] !=
                            null) ...[
                      SizedBox(height: 8),
                      if (widget.responseData['special_price'] != null &&
                          widget.responseData['erp_current_price'] != null) ...[
                        Text(
                          'Base Price: QAR ${double.parse(widget.responseData['regular_price']).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          'Final Price: QAR ${double.parse(widget.responseData['special_price']).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ] else if (widget.responseData['special_price'] == null &&
                          widget.responseData['current_promotion_price'] !=
                              null) ...[
                        Text(
                          'Price: QAR ${double.parse(widget.responseData['current_promotion_price']).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        // Text(
                        //   'Using Base Price (Final Price is 0)',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.orange[600],
                        //     fontStyle: FontStyle.italic,
                        //   ),
                        // ),
                      ] else ...[
                        Text(
                          'Price: QAR ${widget.responseData['final_price'] ?? widget.responseData['price']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ],
                    SizedBox(height: 16),
                    Text(
                      'Do you want to pick this item?',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
        actions:
            isProcessing
                ? []
                : [
                  TextButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () {
                              widget.onCancel?.call();
                              Navigator.of(context).pop(); // Close dialog
                            },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        isProcessing
                            ? null
                            : () async {
                              setState(() {
                                isProcessing = true;
                              });

                              try {
                                // Handle price from API response - check for final_price first
                                String apiPrice = '';
                                if (widget.responseData['final_price'] !=
                                        null &&
                                    widget.responseData['final_price']
                                        .toString()
                                        .isNotEmpty &&
                                    widget.responseData['final_price']
                                            .toString() !=
                                        "0.0000") {
                                  apiPrice =
                                      widget.responseData['final_price']
                                          .toString();
                                } else if (widget.responseData['price'] !=
                                        null &&
                                    widget.responseData['price']
                                        .toString()
                                        .isNotEmpty) {
                                  apiPrice =
                                      widget.responseData['price'].toString();
                                }

                                final success = await widget.cubit
                                    .updateItemStatus(
                                      item: widget.item,
                                      status: 'end_picking',
                                      scannedSku:
                                          widget.responseData['sku'] ?? '',
                                      priceOverride:
                                          apiPrice.isNotEmpty ? apiPrice : null,
                                      isProduceOverride: 1,
                                      quantity: widget.quantity,
                                    );

                                if (success) {
                                  Fluttertoast.showToast(
                                    msg: 'Item picked successfully',
                                    toastLength: Toast.LENGTH_LONG,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.green,
                                  );
                                  if (mounted) {
                                    Navigator.of(context).pop(); // Close dialog
                                    Navigator.of(context).pop(
                                      'updated',
                                    ); // Pop item details page, return to item listing
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                    msg: 'Failed to update item status',
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.red,
                                  );
                                  if (mounted) {
                                    setState(() {
                                      isProcessing = false;
                                    });
                                  }
                                }
                              } catch (e) {
                                Fluttertoast.showToast(
                                  msg: 'Error:  ${e.toString()}',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                );
                                if (mounted) {
                                  setState(() {
                                    isProcessing = false;
                                  });
                                }
                              }
                            },
                    icon:
                        isProcessing
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(Icons.check),
                    label: Text(isProcessing ? 'Processing...' : 'Pick Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
      ),
    );
  }
}
