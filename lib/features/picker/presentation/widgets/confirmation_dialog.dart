import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;
  final OrderItemModel item;
  final OrderDetailsCubit cubit;
  final String status;
  final String reason;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
    required this.item,
    required this.cubit,
    required this.status,
    required this.reason,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _isLoading = false;
  BuildContext? _storedContext;

  @override
  void initState() {
    super.initState();
    _storedContext = context;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Text(widget.message),
      actions: [
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    Navigator.of(context).pop();
                  },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmColor,
            foregroundColor: Colors.white,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(widget.confirmText),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to update item status
      final success = await widget.cubit.updateItemStatus(
        item: widget.item,
        status: widget.status,
        scannedSku: widget.item.sku ?? '',
        reason: widget.reason,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        Fluttertoast.showToast(
          msg:
              'Item ${widget.status == 'item_not_available' ? 'marked as not available' : 'canceled'}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: widget.confirmColor,
        );
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(
            context,
          ).pop('updated'); // Pop item details page, return to item listing
        }
      } else {
        // Show error message
        Fluttertoast.showToast(
          msg: 'Failed to update item status',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToItemListingWithFallback() {
    print('Attempting to navigate to item listing...');

    // Try multiple context references
    final contexts =
        [_storedContext, context].where((ctx) => ctx != null).toList();

    for (final ctx in contexts) {
      if (ctx != null && ctx.mounted) {
        try {
          print('Trying navigation with context: $ctx');

          Navigator.pushReplacementNamed(
            ctx,
            AppRoutes.itemListing,
            arguments: {
              'items':
                  widget.cubit.state is OrderDetailsLoaded
                      ? (widget.cubit.state as OrderDetailsLoaded).toPick
                      : [],
              'title': 'Item Listing',
              'cubit': widget.cubit,
            },
          );

          print('Navigation successful with context: $ctx');
          return;
        } catch (e) {
          print('Navigation failed with context $ctx: $e');
          continue;
        }
      }
    }

    // Fallback: Try to pop back to previous screen
    print('All navigation attempts failed, trying fallback...');
    try {
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Fallback navigation also failed: $e');
    }
  }
}
