import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import 'package:api_gateway/config/api_config.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/barcode_scanner_widget.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import '../../../../core/services/user_storage_service.dart';

class OrderItemDetailsPage extends StatefulWidget {
  final OrderItemModel item;
  final OrderDetailsCubit cubit;

  const OrderItemDetailsPage({
    super.key,
    required this.item,
    required this.cubit,
  });

  @override
  State<OrderItemDetailsPage> createState() => _OrderItemDetailsPageState();
}

class _OrderItemDetailsPageState extends State<OrderItemDetailsPage> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Item Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            if (widget.item.productImages.isNotEmpty)
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.item.productImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${ApiConfig.imageUrl}${widget.item.productImages[index]}',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              // Fallback to single image if no product images
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.item.imageUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.grey,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'SKU: ${widget.item.sku ?? ''}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.deliveryType == 'exp' ? 'Express' : 'No Limit',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'QAR ${widget.item.price!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (widget.item.description != null &&
                widget.item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  widget.item.description!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(AppStrings.quantity, style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      _quantity > 1
                          ? () {
                            setState(() {
                              _quantity--;
                            });
                            widget.cubit.updateQuantity(widget.item, _quantity);
                          }
                          : null,
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                    widget.cubit.updateQuantity(widget.item, _quantity);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Scan Button (only show if item is not picked)
            if (widget.item.status != OrderItemStatus.picked)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Barcode to Pick'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _openScanner(context),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text(AppStrings.notAvailable),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed:
                        widget.item.status == OrderItemStatus.notAvailable
                            ? null
                            : () {
                              widget.cubit.markOutOfStock(widget.item);
                              Navigator.pop(context);
                            },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text(AppStrings.canceled),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                    onPressed:
                        widget.item.status == OrderItemStatus.canceled
                            ? null
                            : () {
                              widget.cubit.markCanceled(widget.item);
                              Navigator.pop(context);
                            },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openScanner(BuildContext context) {
    // Show a brief message about scanning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanning barcode for: ${widget.item.name}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BarcodeScannerWidget(
              title: 'Scan Barcode',
              subtitle: 'Scan the barcode for ${widget.item.name}',
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
        widget.item.sku ?? '',
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
                'Barcode: ${responseData['sku'] ?? 'N/A'}',
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
                widget.cubit.markPicked(widget.item);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Item picked successfully: ${widget.item.name}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // Navigate back to previous page
                Navigator.pop(context);
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                // Mark item as not available (out of stock)
                widget.cubit.markOutOfStock(widget.item);

                // Show message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Item marked as not available for replacement',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );

                // Navigate back to previous page
                Navigator.pop(context);
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
