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

  const ProductFoundDialog({
    Key? key,
    required this.responseData,
    required this.item,
    required this.cubit,
    required this.parentContext,
    this.onSuccess,
    this.onCancel,
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
                                final success = await widget.cubit
                                    .updateItemStatus(
                                      item: widget.item,
                                      status: 'end_picking',
                                      scannedSku:
                                          widget.responseData['sku'] ?? '',
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

  // Fallback navigation method when context is not mounted
  void _navigateToItemListingFallback() {
    print('Using fallback navigation method');
    Fluttertoast.showToast(
      msg: 'Navigation failed. Please go back manually.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.orange,
    );
  }

  // New method to handle navigation with fallback
  // Future<void> _navigateToItemListingWithFallback(
  //   BuildContext currentContext,
  //   BuildContext parentContext,
  // ) async {
  //   print('Attempting to navigate to item listing page...');
  //   try {
  //     await Future.delayed(const Duration(milliseconds: 500));
  //     if (widget.cubit.state is OrderDetailsLoaded) {
  //       final loadedState = widget.cubit.state as OrderDetailsLoaded;
  //       print(
  //         'Cubit state loaded, items count:  [39m${loadedState.toPick.length + loadedState.picked.length + loadedState.canceled.length + loadedState.notAvailable.length}',
  //       );
  //       try {
  //         Navigator.of(
  //           currentContext,
  //           rootNavigator: true,
  //         ).pushReplacementNamed(
  //           AppRoutes.itemListing,
  //           arguments: {
  //             'items': [
  //               ...loadedState.toPick,
  //               ...loadedState.picked,
  //               ...loadedState.canceled,
  //               ...loadedState.notAvailable,
  //             ],
  //             'title': 'Item Listing',
  //             'cubit': widget.cubit,
  //           },
  //         );
  //         print('Navigation to item listing page successful');
  //       } catch (e) {
  //         print('Navigation error: $e');
  //         Navigator.of(
  //           currentContext,
  //           rootNavigator: true,
  //         ).pushReplacementNamed(
  //           AppRoutes.itemListing,
  //           arguments: {
  //             'items': [],
  //             'title': 'Item Listing',
  //             'cubit': widget.cubit,
  //           },
  //         );
  //       }
  //     } else {
  //       print(
  //         'Cubit state is not loaded:  [39m${widget.cubit.state.runtimeType}',
  //       );
  //       Navigator.of(currentContext, rootNavigator: true).pushReplacementNamed(
  //         AppRoutes.itemListing,
  //         arguments: {
  //           'items': [],
  //           'title': 'Item Listing',
  //           'cubit': widget.cubit,
  //         },
  //       );
  //     }
  //   } catch (e) {
  //     print('Navigation error during fallback: $e');
  //     Navigator.of(parentContext, rootNavigator: true).pushReplacementNamed(
  //       AppRoutes.itemListing,
  //       arguments: {
  //         'items': [],
  //         'title': 'Item Listing',
  //         'cubit': widget.cubit,
  //       },
  //     );
  //   }
  // }
}
