import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../../data/models/order_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer';
import '../pages/item_replacement_page.dart';

class ImprovedProductDialog extends StatelessWidget {
  final Map<String, dynamic> responseData;
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final BuildContext parentContext;
  final String barcode;
  final int preparationId;
  final OrderModel order;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const ImprovedProductDialog({
    super.key,
    required this.responseData,
    required this.item,
    required this.cubit,
    required this.parentContext,
    required this.barcode,
    required this.preparationId,
    required this.order,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Log the response data to verify what we're receiving
    log('🔍 ImprovedProductDialog - Response Data: $responseData');
    log('🔍 ImprovedProductDialog - Match: ${responseData['match']}');
    log('🔍 ImprovedProductDialog - Product ID: ${responseData['product_id']}');

    final bool isMatch = responseData['match'] == "1";
    final bool isProductFound = responseData['product_id'] != null;

    if (!isProductFound) {
      // Handle barcode not found case
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Product Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              responseData['message'] ??
                  'Product not found in website or ERP system',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanned Barcode:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(responseData['sku'] ?? barcode),
                ],
              ),
            ),
            if (responseData['suggestion'] != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        responseData['suggestion'],
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel();
            },
            child: Text('OK'),
          ),
        ],
      );
    }

    // Product found - show simplified product information
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isMatch ? Icons.warning : Icons.check_circle,
            color: isMatch ? Colors.orange : Colors.green,
          ),
          SizedBox(width: 8),
          Text(isMatch ? 'Product Not Matching' : 'Product Found'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scanned Product Information
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanned Product:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  responseData['sku_name'] ?? 'Unknown Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'SKU: ${responseData['sku'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Type: ${responseData['product_type'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (responseData['priority'] != null) ...[
                      SizedBox(width: 16),
                      Text(
                        'Priority: ${responseData['priority']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Price: QAR ${_getDisplayPrice()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDeliveryTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getDeliveryTypeColor()),
                      ),
                      child: Text(
                        _getDeliveryTypeText(),
                        style: TextStyle(
                          color: _getDeliveryTypeColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Expected Product Information
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected Product:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  item.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'SKU: ${item.sku ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Action Instructions
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMatch ? Colors.orange[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMatch ? Colors.orange[200]! : Colors.green[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isMatch ? Icons.warning : Icons.check_circle,
                  color: isMatch ? Colors.orange[700] : Colors.green[700],
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMatch
                        ? 'Product does not match. Choose Replace or No.'
                        : 'Product matches. You can proceed with picking.',
                    style: TextStyle(
                      color: isMatch ? Colors.orange[700] : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel();
          },
          child: Text('Cancel'),
        ),

        // Action Buttons based on match
        if (isMatch) ...[
          // Replace Button for non-matching products
          ElevatedButton(
            onPressed: () => _handleReplace(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Replace'),
          ),
          // No Button for non-matching products
          ElevatedButton(
            onPressed: () => _handleNo(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('No'),
          ),
        ] else ...[
          // Pick Button for matching products
          ElevatedButton(
            onPressed: () => _handlePick(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Pick'),
          ),
        ],
      ],
    );
  }

  String _getDisplayPrice() {
    // Priority: current_promotion_price > special_price > regular_price
    if (responseData['current_promotion_price'] != null &&
        responseData['current_promotion_price'].toString() != 'null') {
      return double.parse(
        responseData['current_promotion_price'].toString(),
      ).toStringAsFixed(2);
    }
    if (responseData['special_price'] != null &&
        responseData['special_price'].toString() != 'null') {
      return double.parse(
        responseData['special_price'].toString(),
      ).toStringAsFixed(2);
    }
    return double.parse(
      responseData['regular_price'].toString(),
    ).toStringAsFixed(2);
  }

  Color _getDeliveryTypeColor() {
    final deliveryType =
        responseData['delivery_type']?.toString().toLowerCase();
    if (deliveryType == 'exp') {
      return Colors.red;
    } else if (deliveryType == 'nol') {
      return Colors.blue;
    }
    return Colors.grey;
  }

  String _getDeliveryTypeText() {
    final deliveryType =
        responseData['delivery_type']?.toString().toLowerCase();
    if (deliveryType == 'exp') {
      return 'Express';
    } else if (deliveryType == 'nol') {
      return 'Normal Local';
    }
    return 'Unknown';
  }

  Future<void> _handlePick(BuildContext context) async {
    try {
      Navigator.of(context).pop();

      final success = await cubit.updateItemStatus(
        item: item,
        status: 'end_picking',
        scannedSku: barcode,
        reason: '',
        priceOverride: _getDisplayPrice(),
        isProduceOverride: 0,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: 'Item picked successfully!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
        );
        onSuccess();
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to pick item',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
        onCancel();
      }
    } catch (e) {
      log('Error picking item: $e');
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      onCancel();
    }
  }

  Future<void> _handleReplace(BuildContext context) async {
    try {
      log('🔍 _handleReplace called - navigating to ItemReplacementPage');
      log(
        '🔍 Item: ${item.name}, Barcode: $barcode, PreparationId: $preparationId',
      );

      // Call onSuccess first (like ProductNotMatchingDialog does)
      onSuccess();

      // Navigate to ItemReplacementPage using the same approach as ProductNotMatchingDialog
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ItemReplacementPage(
                item: item,
                barcode: barcode, // Pass the scanned barcode
                preparationId: preparationId,
                orderDetailsCubit: cubit,
                order: order,
              ),
        ),
      );
      log('🔍 Navigation to ItemReplacementPage completed');

      // Check if navigation was successful and close dialog if needed
      if (context.mounted && (result == 'updated' || result == 'replaced')) {
        Navigator.of(context).pop('replaced');
      }

      log('🔍 onSuccess called');
    } catch (e) {
      log('Error navigating to replacement page: $e');
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      onCancel();
    }
  }

  Future<void> _handleNo(BuildContext context) async {
    try {
      Navigator.of(context).pop();

      final success = await cubit.updateItemStatus(
        item: item,
        status: 'item_not_available',
        scannedSku: barcode,
        reason: 'Product not matching - picker declined',
        priceOverride: '0.00',
        isProduceOverride: 0,
      );

      if (success) {
        Fluttertoast.showToast(
          msg: 'Item marked as not available',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
        onSuccess();
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to update item status',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
        onCancel();
      }
    } catch (e) {
      log('Error updating item status: $e');
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      onCancel();
    }
  }
}
