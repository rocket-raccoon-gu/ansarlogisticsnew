import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:developer';
import '../../data/models/order_model.dart';
import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../core/services/call_logs_service.dart';

class CustomerCardWidget extends StatelessWidget {
  final OrderModel order;
  final String? preparationLabel;

  const CustomerCardWidget({
    super.key,
    required this.order,
    this.preparationLabel,
  });

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
                      order.customerFirstname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  if (preparationLabel != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Label: $preparationLabel',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
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
                onPressed: () => _handleCall(),
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

  void _handleCall() async {
    CallLogs c1 = CallLogs();
    await c1.handleCall(order.phone, () async {
      log("📞 Call initiated for order: ${order.preparationId}");
    });
  }

  void _launchWhatsApp(String phone) async {
    try {
      // Get user data for role-based messaging
      final userData = await UserStorageService.getUserData();
      final userName = userData?.user?.name ?? 'Team Member';
      final userRole = userData?.user?.role ?? 3; // Default to picker role

      String contact = phone.trim();
      String androidUrl;
      String iosUrl;

      // Handle special contact number
      if (contact == "+97460094446") {
        androidUrl = "whatsapp://send?phone=$contact&text=Hi, I need some help";
      } else {
        String contactSplit = "";

        if (contact.startsWith('+974') || contact.startsWith('974')) {
          contactSplit = contact;
        } else {
          contactSplit = "+974${contact}";
        }

        log("Formatted contact: $contactSplit");

        // Create role-based message
        String message;
        if (userRole == 1) {
          // Picker role
          message =
              "Hello, this is $userName Your *Ansar Gallery Order Picker*. I am here to assist with Preparing your order ${order.preparationId}";
        } else {
          // Driver role
          message =
              "Hello, this is $userName Your *Ansar Gallery Order Driver*. I am here to assist with Deliver your order ${order.preparationId}";
        }

        androidUrl =
            "whatsapp://send?phone=${contactSplit}&text=${Uri.encodeComponent(message)}";
      }

      iosUrl =
          "https://wa.me/$contact?text=${Uri.encodeComponent('Hi, I need some help')}";

      if (Platform.isIOS) {
        await launchUrl(
          Uri.parse(iosUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          Uri.parse(androidUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      log("Error launching WhatsApp: $e");
      // Fallback to simple WhatsApp launch
      final uri = Uri.parse('https://wa.me/$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
