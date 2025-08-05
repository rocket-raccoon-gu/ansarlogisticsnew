import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';
import '../pages/item_replacement_page.dart';
import '../../data/models/order_model.dart';

class ProductNotMatchingDialog extends StatelessWidget {
  final Map<String, dynamic> responseData;
  final String barcode;
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final VoidCallback? onSuccess;
  final void Function()? onCancel;
  final String preparationId;
  final OrderModel order;
  const ProductNotMatchingDialog({
    Key? key,
    required this.responseData,
    required this.barcode,
    required this.item,
    required this.cubit,
    this.onSuccess,
    this.onCancel,
    required this.preparationId,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isProcessing = false;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Product Not Matching',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
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
                        'Product not matching. Need to replace.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Scanned Barcode: $barcode',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (responseData['expected_barcode'] != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Expected Barcode: ${responseData['expected_barcode']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      Text(
                        'The scanned barcode does not match the expected product.',
                        style: TextStyle(fontSize: 14, color: Colors.red[600]),
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
                                onCancel?.call();
                                Navigator.of(context).pop();
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
                                // try {
                                //   final success = await cubit.updateItemStatus(
                                //     item: item,
                                //     status: 'item_not_available',
                                //     scannedSku: barcode,
                                //     reason:
                                //         'Product not matching - replacement needed',
                                //   );
                                //   if (success) {
                                //     Fluttertoast.showToast(
                                //       msg:
                                //           'Item marked as not available for replacement',
                                //       toastLength: Toast.LENGTH_SHORT,
                                //       gravity: ToastGravity.BOTTOM,
                                //       timeInSecForIosWeb: 1,
                                //       backgroundColor: Colors.orange,
                                //     );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                } // Close dialog
                                //       Navigator.of(context).pop(
                                //         'updated',
                                //       ); // Pop item details page, return to item listing
                                //     }
                                //   } else {
                                //     Fluttertoast.showToast(
                                //       msg: 'Failed to update item status',
                                //       toastLength: Toast.LENGTH_SHORT,
                                //       gravity: ToastGravity.BOTTOM,
                                //       timeInSecForIosWeb: 1,
                                //       backgroundColor: Colors.red,
                                //     );
                                //     setState(() {
                                //       isProcessing = false;
                                //     });
                                //   }
                                // } catch (e) {
                                //   Fluttertoast.showToast(
                                //     msg: 'Error: ${e.toString()}',
                                //     toastLength: Toast.LENGTH_SHORT,
                                //     gravity: ToastGravity.BOTTOM,
                                //     timeInSecForIosWeb: 1,
                                //     backgroundColor: Colors.red,
                                //   );
                                //   setState(() {
                                //     isProcessing = false;
                                //   });
                                // }
                                onSuccess?.call();
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ItemReplacementPage(
                                          item: item,
                                          barcode: barcode,
                                          preparationId: preparationId,
                                          orderDetailsCubit: cubit,
                                          order: order,
                                        ),
                                  ),
                                );
                                if (context.mounted &&
                                    (result == 'updated' ||
                                        result == 'replaced')) {
                                  Navigator.of(context).pop('replaced');
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
                              : Icon(Icons.swap_horiz),
                      label: Text(isProcessing ? 'Processing...' : 'Replace'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
        );
      },
    );
  }

  Future<void> _navigateToItemListingWithFallback(
    BuildContext context,
    BuildContext parentContext,
  ) async {
    try {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.itemListing,
        arguments: {
          'items': [
            ...(cubit.state as OrderDetailsLoaded).toPick,
            ...(cubit.state as OrderDetailsLoaded).picked,
            ...(cubit.state as OrderDetailsLoaded).canceled,
            ...(cubit.state as OrderDetailsLoaded).notAvailable,
          ],
          'title': 'Item Listing',
          'cubit': cubit,
          'preparationId': preparationId,
          'orderNumber': preparationId,
          'order': order,
        },
      );
    } catch (e) {
      print('Navigation error: $e');
      // Fallback navigation
      Navigator.pushReplacementNamed(
        parentContext,
        AppRoutes.itemListing,
        arguments: {
          'items': [],
          'title': 'Item Listing',
          'cubit': cubit,
          'preparationId': preparationId,
          'orderNumber': preparationId,
          'order': order,
        },
      );
    }
  }
}
