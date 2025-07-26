import 'package:ansarlogisticsnew/core/constants/app_methods.dart';
import 'package:flutter/material.dart';
import '../../data/models/driver_order_model.dart';
import 'direction_options_dialog.dart';

class DriverOrderListItem extends StatelessWidget {
  final DriverOrderModel order;
  final VoidCallback? onTap;

  const DriverOrderListItem({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(order.driverStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getStatusText(order.driverStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (order.dropoff.zone.isNotEmpty)
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(order.dropoff.zone)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(order.dropoff.street)),
                      ],
                    ),
                  ],
                ),
              if (order.customer.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Customer: ${order.customer.name}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text('View Direction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => DirectionOptionsDialog(
                            destinationLat: order.dropoff.latitude,
                            destinationLong: order.dropoff.longitude,
                            destinationName:
                                order.dropoff.zone.isNotEmpty
                                    ? order.dropoff.zone
                                    : order.dropoff.street,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
