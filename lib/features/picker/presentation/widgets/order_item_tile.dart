import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import 'package:ansarlogisticsnew/core/constants/app_methods.dart';
import 'package:ansarlogisticsnew/core/constants/app_colors.dart';
import 'package:api_gateway/config/api_config.dart';
import 'stable_scanner_widget.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import '../../../../core/services/user_storage_service.dart';
import 'package:ansarlogisticsnew/core/widgets/network_image_with_loader.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onItemPicked;

  const OrderItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onItemPicked,
  });

  // Helper method to get the correct display price
  String _getDisplayPrice(OrderItemModel item) {
    // Check if finalPrice is available and not zero
    if (item.finalPrice != null && item.finalPrice! > 0) {
      return item.finalPrice!.toStringAsFixed(2);
    }
    // Fall back to price if finalPrice is null or zero
    return item.price?.toStringAsFixed(2) ?? '0.00';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive design based on screen width
        final isSmallScreen = constraints.maxWidth < 400;
        final isMediumScreen =
            constraints.maxWidth >= 400 && constraints.maxWidth < 600;
        final isLargeScreen = constraints.maxWidth >= 600;

        // Responsive image size
        final imageSize =
            isSmallScreen
                ? 95.0
                : isMediumScreen
                ? 120.0
                : 140.0;

        // Responsive text sizes
        final titleFontSize =
            isSmallScreen
                ? 14.0
                : isMediumScreen
                ? 16.0
                : 18.0;
        final detailFontSize =
            isSmallScreen
                ? 12.0
                : isMediumScreen
                ? 13.0
                : 14.0;
        final priceFontSize =
            isSmallScreen
                ? 12.0
                : isMediumScreen
                ? 13.0
                : 14.0;

        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 6 : 8,
          ),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image - Larger and more prominent
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: NetworkImageWithLoader(
                          imageUrl:
                              item.productImages.isNotEmpty
                                  ? '${ApiConfig.imageUrl}${item.productImages.first}'
                                  : item.imageUrl,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),

                  // Product Details - Flexible and responsive
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: titleFontSize,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 4 : 6),

                        // SKU and Quantity Row
                        Row(
                          children: [
                            // SKU
                            // Expanded(
                            //   flex: 2,
                            //   child: Row(
                            //     children: [
                            //       Text(
                            //         'SKU: ',
                            //         style: TextStyle(
                            //           fontSize: detailFontSize,
                            //           color: Colors.grey[600],
                            //         ),
                            //       ),
                            Flexible(
                              child: Text(
                                item.sku ?? '-',
                                style: TextStyle(
                                  fontSize: detailFontSize,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // ],
                            //   ),
                            // ),

                            // Quantity
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: detailFontSize + 2,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Qty: ${item.quantity}',
                                style: TextStyle(
                                  fontSize: detailFontSize,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 4 : 6),

                        // Price Row - Simplified and more readable
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    item.isProduce
                                        ? Colors.green[50]
                                        : Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      item.isProduce
                                          ? Colors.green[200]!
                                          : Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'QAR ${_getDisplayPrice(item)}',
                                    style: TextStyle(
                                      fontSize: priceFontSize,
                                      color:
                                          item.isProduce
                                              ? Colors.green[700]
                                              : Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.isProduce) ...[
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.eco,
                                      size: priceFontSize,
                                      color: Colors.green[600],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Status Badge - Compact and responsive
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    isSmallScreen
                                        ? 80
                                        : isMediumScreen
                                        ? 100
                                        : 120,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  item.status.toString().split('.').last,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                getStatusText(
                                  item.status.toString().split('.').last,
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 11 : detailFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SizedBox(width: 8),

                  // Status Badge - Compact and responsive
                  // Container(
                  //   constraints: BoxConstraints(
                  //     maxWidth:
                  //         isSmallScreen
                  //             ? 80
                  //             : isMediumScreen
                  //             ? 100
                  //             : 120,
                  //   ),
                  //   padding: EdgeInsets.symmetric(
                  //     horizontal: isSmallScreen ? 8 : 10,
                  //     vertical: isSmallScreen ? 4 : 6,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: getStatusColor(
                  //       item.status.toString().split('.').last,
                  //     ),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Text(
                  //     getStatusText(item.status.toString().split('.').last),
                  //     style: TextStyle(
                  //       color: Colors.white,
                  //       fontSize: isSmallScreen ? 11 : detailFontSize,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //     overflow: TextOverflow.ellipsis,
                  //     maxLines: 1,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openScanner(BuildContext context) {
    // Show a brief message about scanning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanning barcode for: ${item.name}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StableScannerWidget(
              title: 'Scan Barcode',
              subtitle: 'Scan the barcode for ${item.name}',
              onBarcodeScanned:
                  (barcode) => _handleBarcodeScanned(context, barcode),
            ),
      ),
    );
  }

  Future<void> _handleBarcodeScanned(
    BuildContext context,
    String barcode,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get user token
      final userData = await UserStorageService.getUserData();
      final token = userData?.token;

      if (token == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call API to scan barcode and pick item
      final apiService = ApiService(HttpClient(), WebSocketClient());
      final response = await apiService.scanBarcodeAndPickItem(
        barcode,
        token,
        item.sku ?? '',
      );

      // Close loading dialog
      Navigator.pop(context);

      // Check API response
      if (response.data != null && response.data['match'] == "0") {
        // Close scanner on success
        Navigator.pop(context);

        // Show product found dialog with pickup button
        _showProductFoundDialog(context, response.data);
      } else if (response.data != null && response.data['match'] == "1") {
        // Close scanner
        Navigator.pop(context);

        // Show product not matching dialog with replace button
        _showProductNotMatchingDialog(context, response.data, barcode);
      } else {
        // Show error message from API but don't close scanner
        final errorMessage = response.data?['message'] ?? 'Failed to pick item';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Don't close scanner - let user retry
        // The scanner will automatically resume after 1 second due to the debounce mechanism
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick item: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Don't close scanner - let user retry
      // The scanner will automatically resume after 1 second due to the debounce mechanism
    }
  }

  void _showProductFoundDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
                'Barcode: ${responseData['barcode'] ?? 'N/A'}',
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                // Mark item as picked
                // Note: We need to update the item status through the cubit
                // This will be handled by the parent widget's onItemPicked callback

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item picked successfully: ${item.name}'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Notify parent to refresh items
                onItemPicked?.call();
              },
              icon: Icon(Icons.check),
              label: Text('Pick Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductNotMatchingDialog(
    BuildContext context,
    Map<String, dynamic> responseData,
    String barcode,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Product Not Matching',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                // Mark item as not available (out of stock)
                // This will be handled by the parent widget's onItemPicked callback

                // Show message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Item marked as not available for replacement',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );

                // Notify parent to refresh items
                onItemPicked?.call();
              },
              icon: Icon(Icons.swap_horiz),
              label: Text('Replace'),
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
}
