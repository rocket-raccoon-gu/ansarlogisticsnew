import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';

class ProductFoundDialog extends StatelessWidget {
  final Map<String, dynamic> responseData;
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final VoidCallback? onSuccess;

  const ProductFoundDialog({
    Key? key,
    required this.responseData,
    required this.item,
    required this.cubit,
    this.onSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isProcessing = false;

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product found in database with barcode:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Barcode:  [39m${responseData['sku'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (responseData['product_name'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Product: ${responseData['product_name']}',
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
                          // Navigator.of(context).pop();

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
                            // Call API to update item status to end_picking
                            final success = await cubit.updateItemStatus(
                              item: item,
                              status: 'end_picking',
                              scannedSku: responseData['sku'] ?? '',
                            );

                            // Close loading dialog safely
                            if (currentContext.mounted) {
                              Navigator.of(currentContext).pop();
                            }

                            if (success) {
                              // Show success message
                              Fluttertoast.showToast(
                                msg: 'Item picked successfully',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.green,
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
      },
    );
  }

  // Fallback navigation method when context is not mounted
  void _navigateToItemListingFallback() {
    print('Using fallback navigation method');
    // Try to use a global navigator key or other approach
    // For now, just show a message that navigation failed
    Fluttertoast.showToast(
      msg: 'Navigation failed. Please go back manually.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.orange,
    );
  }

  // New method to handle navigation with fallback
  Future<void> _navigateToItemListingWithFallback(
    BuildContext currentContext,
    BuildContext parentContext,
  ) async {
    print('Attempting to navigate to item listing page...');
    try {
      // Wait a bit for the toast to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if cubit state is loaded
      if (cubit.state is OrderDetailsLoaded) {
        final loadedState = cubit.state as OrderDetailsLoaded;
        print(
          'Cubit state loaded, items count: ${loadedState.toPick.length + loadedState.picked.length + loadedState.canceled.length + loadedState.notAvailable.length}',
        );

        try {
          Navigator.pushReplacementNamed(
            currentContext,
            AppRoutes.itemListing,
            arguments: {
              'items': [
                ...loadedState.toPick,
                ...loadedState.picked,
                ...loadedState.canceled,
                ...loadedState.notAvailable,
              ],
              'title': 'Item Listing',
              'cubit': cubit,
            },
          );
          print('Navigation to item listing page successful');
        } catch (e) {
          print('Navigation error: $e');
          // Fallback navigation
          Navigator.pushReplacementNamed(
            currentContext,
            AppRoutes.itemListing,
            arguments: {'items': [], 'title': 'Item Listing', 'cubit': cubit},
          );
        }
      } else {
        print('Cubit state is not loaded: ${cubit.state.runtimeType}');
        // Fallback navigation without state
        Navigator.pushReplacementNamed(
          currentContext,
          AppRoutes.itemListing,
          arguments: {'items': [], 'title': 'Item Listing', 'cubit': cubit},
        );
      }
    } catch (e) {
      print('Navigation error during fallback: $e');
      // Fallback navigation
      Navigator.pushReplacementNamed(
        parentContext,
        AppRoutes.itemListing,
        arguments: {'items': [], 'title': 'Item Listing', 'cubit': cubit},
      );
    }
  }
}
