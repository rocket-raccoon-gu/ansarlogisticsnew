import 'package:ansarlogisticsnew/core/constants/app_strings.dart';

import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/order_item_tile.dart';
// import 'order_item_details_page.dart'; // To be created
import 'order_item_details_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/item_listing_page.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => OrderDetailsCubit(
            orderId: widget.order.preparationId,
            apiService: ApiService(HttpClient(), WebSocketClient()),
          ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${AppStrings.orderId} #${widget.order.preparationId}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildCustomerCard(widget.order),
            _buildTypeCards(context, widget.order),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(
    BuildContext context,
    List<OrderItemModel> items,
    String emptyText,
  ) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }
    final cubit = BlocProvider.of<OrderDetailsCubit>(context);
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return OrderItemTile(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderItemDetailsPage(item: item, cubit: cubit),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
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

  Widget _buildTypeCards(BuildContext context, OrderModel order) {
    final items = order.items;
    final expItems = items.where((item) => item.deliveryType == 'exp').toList();
    final nolItems = items.where((item) => item.deliveryType == 'nol').toList();
    final hasEXP = expItems.isNotEmpty;
    final hasNOL = nolItems.isNotEmpty;
    if (!hasEXP && !hasNOL) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (hasEXP)
            Expanded(
              child: Card(
                color: Colors.orange[100],
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: expItems,
                              title: 'Express Items',
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'EXP (Express)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (hasNOL)
            Expanded(
              child: Card(
                color: Colors.blue[100],
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: nolItems,
                              title: 'Normal Local Items',
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'NOL (Normal Local)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
