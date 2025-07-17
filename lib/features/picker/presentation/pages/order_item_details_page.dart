import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';

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
      appBar: AppBar(title: Text(widget.item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              widget.item.name,
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text(AppStrings.toPick),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed:
                        widget.item.status == OrderItemStatus.picked
                            ? null
                            : () {
                              widget.cubit.markPicked(widget.item);
                              Navigator.pop(context);
                            },
                  ),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(AppStrings.canceled),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
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
      ),
    );
  }
}
