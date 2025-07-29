import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';

class CustomerCommentWidget extends StatelessWidget {
  final OrderModel order;
  final List<OrderItemModel>? orderItems;
  final String? deliveryNote;

  const CustomerCommentWidget({
    super.key,
    required this.order,
    this.orderItems,
    this.deliveryNote,
  });

  @override
  Widget build(BuildContext context) {
    // Get all delivery notes from order items
    final deliveryNotes = [deliveryNote ?? ''];

    // Don't show widget if there are no delivery notes
    if (deliveryNotes.isEmpty || deliveryNotes[0] == '') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.amber.shade50],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.note_alt_outlined,
                        size: 22,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Notes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          Text(
                            'Customer instructions for this order',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Priority indicator if any note contains urgent keywords
                    if (deliveryNotes.any((note) => _isUrgentComment(note)))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 12,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Display all delivery notes
                ...deliveryNotes
                    .map(
                      (note) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isUrgentComment(note))
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.priority_high,
                                      size: 12,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'URGENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              note,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get all delivery notes from order items
  List<String> _getDeliveryNotes() {
    final notes = <String>[];

    // First check if we have orderItems passed directly
    if (orderItems != null) {
      for (final item in orderItems!) {
        if (item.deliveryNote != null && item.deliveryNote!.isNotEmpty) {
          notes.add(item.deliveryNote!);
        }
      }
    } else {
      // Fallback to order.items if orderItems is not provided
      for (final item in order.items) {
        if (item.deliveryNote != null && item.deliveryNote!.isNotEmpty) {
          notes.add(item.deliveryNote!);
        }
      }
    }

    // Remove duplicates while preserving order
    final uniqueNotes = <String>[];
    for (final note in notes) {
      if (!uniqueNotes.contains(note)) {
        uniqueNotes.add(note);
      }
    }

    return uniqueNotes;
  }

  // Check if comment contains urgent keywords
  bool _isUrgentComment(String comment) {
    final urgentKeywords = [
      'urgent',
      'asap',
      'immediately',
      'quick',
      'fast',
      'rush',
      'emergency',
      'important',
      'priority',
    ];

    final lowerComment = comment.toLowerCase();
    return urgentKeywords.any((keyword) => lowerComment.contains(keyword));
  }
}
