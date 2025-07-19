import 'package:ansarlogisticsnew/core/constants/app_strings.dart';

import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_details_model.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/customer_card_widget.dart';
import '../widgets/type_cards_widget.dart';
import '../widgets/item_list_widget.dart';
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
      create: (context) {
        final cubit = OrderDetailsCubit(
          orderId: widget.order.preparationId,
          apiService: ApiService(HttpClient(), WebSocketClient()),
        );
        // Load items after cubit is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cubit.loadItems();
        });
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${AppStrings.orderId} #${widget.order.preparationId}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
          builder: (context, state) {
            if (state is OrderDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is OrderDetailsError) {
              return Center(child: Text(state.message));
            } else if (state is OrderDetailsLoaded) {
              return Column(
                children: [
                  CustomerCardWidget(order: widget.order),
                  TypeCardsWidget(
                    allItems: [
                      ...state.toPick,
                      ...state.picked,
                      ...state.canceled,
                      ...state.notAvailable,
                    ],
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
