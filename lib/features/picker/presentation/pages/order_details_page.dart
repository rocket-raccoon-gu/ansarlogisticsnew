import 'package:flutter/material.dart';
import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_details_model.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/customer_card_widget.dart';
import '../widgets/type_cards_widget.dart';
import '../widgets/item_list_widget.dart';
import 'order_item_details_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/picker_orders_page.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import '../cubit/picker_orders_cubit.dart';

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
              // Shimmer/skeleton loader
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder:
                    (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: 80,
                    ),
              );
            } else if (state is OrderDetailsError) {
              return Center(child: Text(state.message));
            } else if (state is OrderDetailsLoaded) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        CustomerCardWidget(order: widget.order),
                        TypeCardsWidget(
                          allItems: [
                            ...state.toPick,
                            ...state.picked,
                            ...state.canceled,
                            ...state.notAvailable,
                          ],
                          cubit: BlocProvider.of<OrderDetailsCubit>(context),
                          preparationId: int.parse(widget.order.preparationId),
                          order: widget.order,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section header for picking actions
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Order Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // End Picking button (primary action)
                        ElevatedButton.icon(
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text(
                            'End Picking',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            side: BorderSide(color: Colors.green, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final cubit = BlocProvider.of<OrderDetailsCubit>(
                              context,
                            );
                            final state = cubit.state;
                            if (state is OrderDetailsLoaded) {
                              final hasUnpicked = state.toPick.isNotEmpty;
                              if (hasUnpicked) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text('Cannot End Picking'),
                                        content: Text(
                                          'You must pick or update the status of all items before ending picking. Items with status "To Pick" (start_picking) remain.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                                return;
                              }
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('End Picking'),
                                      content: Text(
                                        'Are you sure you want to end picking for this order?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: Text('No'),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: Text('Yes'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed == true) {
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                  );
                                  await cubit.endPicking(orderNumber: '');
                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Picking ended successfully.',
                                        ),
                                      ),
                                    );
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => BlocProvider(
                                              create:
                                                  (_) => PickerOrdersCubit(),
                                              child: PickerOrdersPage(),
                                            ),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(); // Dismiss loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        // Section header for cancel
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Other Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(
                            Icons.cancel_schedule_send,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Cancel Request for All Order',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.red, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Cancel Request for All Order'),
                                    content: Text(
                                      'Are you sure you want to send a cancel request for the entire order?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: Text('No'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: Text('Yes'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirmed == true) {
                              try {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                );
                                await BlocProvider.of<OrderDetailsCubit>(
                                  context,
                                ).cancelOrder(orderNumber: '');
                                if (mounted) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(); // Dismiss loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cancel request for all order sent successfully.',
                                      ),
                                    ),
                                  );
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BlocProvider(
                                            create: (_) => PickerOrdersCubit(),
                                            child: PickerOrdersPage(),
                                          ),
                                    ),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(); // Dismiss loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
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
