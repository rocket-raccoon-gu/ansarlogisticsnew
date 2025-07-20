import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';

class ProductNotMatchingDialog extends StatelessWidget {
  final Map<String, dynamic> responseData;
  final String barcode;
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final VoidCallback? onSuccess;

  const ProductNotMatchingDialog({
    Key? key,
    required this.responseData,
    required this.barcode,
    required this.item,
    required this.cubit,
    this.onSuccess,
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
              Text('Product Not Matching'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product not matching. Need to replace.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
              SizedBox(height: 16),
              Text(
                'The scanned barcode does not match the expected product.',
                style: TextStyle(fontSize: 14, color: Colors.red[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isProcessing
                      ? null
                      : () {
                        Navigator.of(context).pop(); // Close dialog
                      },
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed:
                  isProcessing
                      ? null
                      : () async {
                        // Set processing state to disable button
                        setState(() {
                          isProcessing = true;
                        });

                        // Store context reference before any async operations
                        final currentContext = context;

                        // Store the parent context before closing dialog
                        final parentContext = Navigator.of(context).context;

                        // Close dialog first
                        Navigator.of(context).pop();

                        // Use a more robust loading approach
                        showDialog(
                          context: currentContext,
                          barrierDismissible: false,
                          builder:
                              (BuildContext loadingContext) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        try {
                          // Call API to update item status to item_not_available
                          final success = await cubit.updateItemStatus(
                            item: item,
                            status: 'item_not_available',
                            scannedSku: barcode,
                            reason: 'Product not matching - replacement needed',
                          );

                          // Close loading dialog safely
                          if (currentContext.mounted) {
                            Navigator.of(currentContext).pop();
                          }

                          if (success) {
                            // Show message
                            Fluttertoast.showToast(
                              msg:
                                  'Item marked as not available for replacement',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.orange,
                            );

                            // Refresh the cubit to update item status
                            await cubit.loadItems();

                            // Try navigation with multiple context options
                            await _navigateToItemListingWithFallback(
                              currentContext,
                              parentContext,
                            );
                          } else {
                            // Show error message
                            Fluttertoast.showToast(
                              msg: 'Failed to update item status',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                            );
                          }
                        } catch (e) {
                          // Close loading dialog safely
                          if (currentContext.mounted) {
                            Navigator.of(currentContext).pop();
                          }

                          // Show error message
                          Fluttertoast.showToast(
                            msg: 'Error: ${e.toString()}',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.red,
                          );
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
        },
      );
    } catch (e) {
      print('Navigation error: $e');
      // Fallback navigation
      Navigator.pushReplacementNamed(
        parentContext,
        AppRoutes.itemListing,
        arguments: {'items': [], 'title': 'Item Listing', 'cubit': cubit},
      );
    }
  }
}
