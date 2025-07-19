import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/order_model.dart';
import 'package:ansarlogisticsnew/core/constants/app_strings.dart';

class CustomerCardWidget extends StatelessWidget {
  final OrderModel order;

  const CustomerCardWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.customerFirstname == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.customerFirstname != null)
                    Text(
                      order.customerFirstname!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  if (order.phone != null)
                    Text(
                      '${AppStrings.customerPhone}: ${order.phone}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (order.phone != null)
                    Text(
                      '${AppStrings.customerWhatsapp}: ${order.phone}',
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
            if (order.phone != null)
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _launchPhone(order.phone!),
                tooltip: AppStrings.call,
              ),
            if (order.phone != null)
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.green,
                ),
                onPressed: () => _launchWhatsApp(order.phone),
                tooltip: AppStrings.whatsapp,
              ),
          ],
        ),
      ),
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
