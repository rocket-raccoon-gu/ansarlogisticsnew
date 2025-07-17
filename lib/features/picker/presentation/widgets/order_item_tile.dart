import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import 'package:ansarlogisticsnew/core/constants/app_methods.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItemModel item;
  final VoidCallback? onTap;

  const OrderItemTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 48, color: Colors.grey),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Qty: ${item.quantity}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor(item.status.name),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getStatusText(item.status.name),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
