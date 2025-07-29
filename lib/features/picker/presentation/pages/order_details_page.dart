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
import '../widgets/customer_comment_widget.dart';
import '../widgets/cancel_reason_dialog.dart';
import '../widgets/type_cards_widget.dart';
import '../widgets/item_list_widget.dart';
import 'order_item_details_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/picker_orders_page.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import '../cubit/picker_orders_cubit.dart';
import 'package:ansarlogisticsnew/features/navigation/presentation/pages/main_navigation_page.dart';

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
          title: Text(
            '${AppStrings.orderId} #${widget.order.preparationId}',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Data Available',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Unable to load order details. Please try again later.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrderDetailsCubit>().loadItems();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is OrderDetailsLoaded) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        CustomerCardWidget(
                          order: widget.order,
                          preparationLabel:
                              state.preparationLabel.isNotEmpty
                                  ? state.preparationLabel
                                  : null,
                        ),
                        CustomerCommentWidget(
                          order: widget.order,
                          deliveryNote: state.deliveryNote,
                          orderItems: [
                            ...state.toPick,
                            ...state.picked,
                            ...state.canceled,
                            ...state.notAvailable,
                          ],
                        ),
                        TypeCardsWidget(
                          allItems: [
                            ...state.toPick,
                            ...state.picked,
                            ...state.canceled,
                            ...state.notAvailable,
                          ],
                          cubit: BlocProvider.of<OrderDetailsCubit>(context),
                          preparationId: _parsePreparationId(
                            widget.order.preparationId,
                          ),
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
                                              child: const MainNavigationPage(),
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
                            // Show cancel reason selection dialog
                            final result =
                                await showDialog<Map<String, String?>>(
                                  context: context,
                                  builder:
                                      (context) => const CancelReasonDialog(),
                                );

                            print('🔍 Cancel dialog result: $result');

                            if (result == null) {
                              // User cancelled the dialog
                              print('🔍 User cancelled the cancel dialog');
                              return;
                            }

                            final cancelReason = result['reason'];
                            final reasonId = result['reasonId'];

                            print('🔍 Cancel reason: $cancelReason');
                            print('🔍 Reason ID: $reasonId');

                            if (cancelReason == null || reasonId == null) {
                              // Invalid result
                              print('❌ Invalid cancel reason result');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invalid cancel reason selected',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Show confirmation dialog with selected reason
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Confirm Cancel Request'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Are you sure you want to send a cancel request for the entire order?',
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.shade200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Selected Reason:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                cancelReason,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Yes, Cancel Order'),
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
                                ).cancelOrder(
                                  orderNumber: '',
                                  cancelReason: cancelReason,
                                );

                                print(
                                  '✅ Cancel order API call completed with reason: $cancelReason',
                                );

                                if (mounted) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(); // Dismiss loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cancel request sent successfully with reason: $cancelReason',
                                      ),
                                      backgroundColor: Colors.orange.shade600,
                                    ),
                                  );
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BlocProvider(
                                            create: (_) => PickerOrdersCubit(),
                                            child: const MainNavigationPage(),
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
                                    backgroundColor: Colors.red.shade600,
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

  int _parsePreparationId(String preparationId) {
    try {
      return int.parse(preparationId);
    } catch (e) {
      // Fallback to 0 or throw an error if parsing is critical
      // For now, we'll return 0 as a fallback
      return 0;
    }
  }
}
