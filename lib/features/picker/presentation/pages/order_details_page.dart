import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ansarlogisticsnew/core/constants/app_methods.dart';
import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../widgets/cancel_reason_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ansarlogisticsnew/features/picker/presentation/pages/item_listing_page.dart';
import 'package:ansarlogisticsnew/features/driver/data/models/caller_model.dart';

import '../cubit/picker_orders_cubit.dart';
import 'package:ansarlogisticsnew/features/navigation/presentation/pages/main_navigation_page.dart';
import '../../../../core/widgets/safe_app_bar.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  final OrderDetailsCubit? existingCubit;

  const OrderDetailsPage({super.key, required this.order, this.existingCubit});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  int _selectedIndex = 0;

  CallLogs c1 = CallLogs();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Use existing cubit if provided, otherwise create a new one
        final cubit =
            widget.existingCubit ??
            OrderDetailsCubit(
              orderId: widget.order.preparationLabel ?? '',
              apiService: ApiService(HttpClient(), WebSocketClient()),
            );

        // Load items after cubit is created (only if it's a new cubit)
        if (widget.existingCubit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              cubit.loadItems();
            }
          });
        }
        return cubit;
      },
      child: Scaffold(
        appBar: SafeAppBar(
          title: '${AppStrings.orderId} #${widget.order.preparationLabel}',
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
          builder: (context, state) {
            if (state is OrderDetailsLoading) {
              return _buildLoadingState();
            } else if (state is OrderDetailsError) {
              return _buildErrorState(context);
            } else if (state is OrderDetailsLoaded) {
              return _buildLoadedState(
                context,
                state,
                context.read<OrderDetailsCubit>(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
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
              if (mounted) {
                context.read<OrderDetailsCubit>().loadItems();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    OrderDetailsLoaded state,
    OrderDetailsCubit cubit,
  ) {
    return Column(
      children: [
        // Main content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Information Card - Priority 1
                _buildCustomerCard(state),

                const SizedBox(height: 10),

                // Delivery Notes Card - Priority 2
                _buildDeliveryNotesCard(state),

                const SizedBox(height: 10),

                // Picking Status Cards - Priority 3
                _buildPickingStatusCards(context, state, cubit),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Action Buttons - Fixed at bottom
        if (state.status != 'cancel_request' && state.status != 'end_picking')
          _buildActionButtons(context, state, cubit)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildCustomerCard(OrderDetailsLoaded state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Name
            Text(
              '${widget.order.customerFirstname} ${widget.order.customerLastname ?? ''}'
                  .trim(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            // Label
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //   decoration: BoxDecoration(
            //     color: Colors.blue[50],
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(color: Colors.blue[200]!),
            //   ),
            //   child: Text(
            //     '${state.preparationLabel.isNotEmpty ? state.preparationLabel : widget.order.preparationLabel ?? ''}',
            //     style: TextStyle(
            //       fontSize: 14,
            //       fontWeight: FontWeight.w600,
            //       color: Colors.blue[700],
            //     ),
            //   ),
            // ),

            // Contact Information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Phone: ${widget.order.phone}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed:
                                    () => _makePhoneCall(widget.order.phone),
                                icon: Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                tooltip: 'Call Customer',
                              ),
                              IconButton(
                                onPressed:
                                    () => _openWhatsApp(
                                      widget.order.phone,
                                      state.username,
                                      widget.order.preparationLabel,
                                    ),
                                icon: Icon(
                                  Icons.message,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                tooltip: 'WhatsApp Customer',
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Payment Method
                      if (state.paymentMethod?.isNotEmpty == true) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payment: ${getPaymentMethodText(state.paymentMethod ?? '')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryNotesCard(OrderDetailsLoaded state) {
    if (state.deliveryNote?.isEmpty ?? true) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.orange[700], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(
                      state.deliveryNote ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickingStatusCards(
    BuildContext context,
    OrderDetailsLoaded state,
    OrderDetailsCubit cubit,
  ) {
    final allItems = [
      ...state.toPick,
      ...state.picked,
      ...state.canceled,
      ...state.notAvailable,
      ...state.holded,
    ];

    // Group items by delivery type
    final expItems =
        allItems.where((item) => item.deliveryType == 'exp').toList();
    final nolItems =
        allItems.where((item) => item.deliveryType == 'nol').toList();
    final warItems =
        allItems.where((item) => item.deliveryType == 'war').toList();
    final supItems =
        allItems.where((item) => item.deliveryType == 'sup').toList();
    final vpoItems =
        allItems.where((item) => item.deliveryType == 'vpo').toList();
    final abyItems =
        allItems.where((item) => item.deliveryType == 'aby').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery Type Cards in a grid
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            if (expItems.isNotEmpty)
              _buildDeliveryTypeCard(
                context,
                'EXP (Express)',
                expItems,
                state.expStatus,
                Colors.orange,
                cubit,
                'exp',
                expItems.isNotEmpty
                    ? expItems.first.subgroupIdentifier ?? ''
                    : '',
                state.expTotal ?? '0',
              ),
            if (nolItems.isNotEmpty)
              _buildDeliveryTypeCard(
                context,
                'NOL (Normal Local)',
                nolItems,
                state.nolStatus,
                Colors.blue,
                cubit,
                'nol',
                nolItems.isNotEmpty
                    ? nolItems.first.subgroupIdentifier ?? ''
                    : '',
                state.nolTotal ?? '0',
              ),
            if (warItems.isNotEmpty)
              _buildDeliveryTypeCard(
                context,
                'WAR (Warehouse)',
                warItems,
                state.warStatus,
                Colors.purple,
                cubit,
                'war',
                warItems.isNotEmpty
                    ? warItems.first.subgroupIdentifier ?? ''
                    : '',
                state.warTotal ?? '0',
              ),
            if (supItems.isNotEmpty)
              _buildDeliveryTypeCard(
                context,
                'SUP (Supply)',
                supItems,
                state.supStatus,
                Colors.teal,
                cubit,
                'sup',
                supItems.isNotEmpty
                    ? supItems.first.subgroupIdentifier ?? ''
                    : '',
                state.supTotal ?? '0',
              ),
            if (vpoItems.isNotEmpty)
              _buildDeliveryTypeCard(
                context,
                'VPO (Vendor PO)',
                vpoItems,
                state.vpoStatus,
                Colors.indigo,
                cubit,
                'vpo',
                vpoItems.isNotEmpty
                    ? vpoItems.first.subgroupIdentifier ?? ''
                    : '',
                state.vpoTotal ?? '0',
              ),
            if (abyItems.isNotEmpty)
              _buildDeliveryTypeCard(
                context,
                'ABY (Abyssinia)',
                abyItems,
                state.abyStatus,
                Colors.brown,
                cubit,
                'aby',
                abyItems.isNotEmpty
                    ? abyItems.first.subgroupIdentifier ?? ''
                    : '',
                state.abyTotal ?? '0',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryTypeCard(
    BuildContext context,
    String title,
    List<OrderItemModel> items,
    String? status,
    MaterialColor color,
    OrderDetailsCubit cubit,
    String deliveryType,
    String orderNumber,
    String total,
  ) {
    final pickedCount =
        items.where((item) => item.status.toString().contains('picked')).length;
    final totalCount = items.length;

    return Card(
      elevation: 2,
      color: color[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            () =>
                status == 'cancel_request' || status == null
                    ? null
                    : _navigateToItemList(
                      context,
                      title,
                      items,
                      cubit,
                      deliveryType,
                      orderNumber,
                    ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Progress Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color[100],
                  border: Border.all(color: color[300]!, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$pickedCount/$totalCount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color[700],
                    ),
                  ),
                ),
              ),

              // Title
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Total: $total",
                        style: TextStyle(
                          fontSize: 12,
                          color: color[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // // Total
              // Text(
              //   'Total: $total',
              //   style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              // ),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed:
                      () => _handleDeliveryTypeAction(
                        context,
                        title,
                        status ?? '',
                        items,
                        cubit,
                        deliveryType,
                        orderNumber,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        status == 'cancel_request' ? Colors.grey : color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    status == null ? 'Delivered' : getStatusText(status ?? ''),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    OrderDetailsLoaded state,
    OrderDetailsCubit cubit,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),

          // End Picking Button
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleEndPicking(context, state),
          ),

          const SizedBox(height: 8),

          // Customer Not Answering Button
          ElevatedButton.icon(
            icon: Icon(Icons.phone_disabled, color: Colors.amber[700]),
            label: Text(
              'Customer Not Answering',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.amber[700]!, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleCustomerNotAnswering(context),
          ),

          const SizedBox(height: 8),

          // Cancel Request Button
          ElevatedButton.icon(
            icon: Icon(Icons.cancel_schedule_send, color: Colors.red),
            label: Text(
              'Cancel Request for All Order',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleCancelRequest(context),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _makePhoneCall(String? phoneNumber) {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      c1.call(phoneNumber, () {
        log("📞 Call initiated for driver order: $phoneNumber");
      });
    }
  }

  void _openWhatsApp(String? phoneNumber, String? username, String? ordernum) {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // whatsapp://send?phone=${phoneNumber}&text=Hello,this is ${UserController.userController.profile.name} Your *Ansar Gallery Order Picker*. I am here to assist with Preparing your order ${ordernum}
      // launchUrl(Uri.parse('https://wa.me/$phoneNumber'));
      launchUrl(
        Uri.parse(
          'whatsapp://send?phone=${phoneNumber}&text=Hello,this is ${username} Your *Ansar Gallery Order Picker*. I am here to assist with Preparing your order ${ordernum}',
        ),
      );
    }
  }

  void _navigateToItemList(
    BuildContext context,
    String title,
    List<OrderItemModel> items,
    OrderDetailsCubit cubit,
    String deliveryType,
    String orderNumber,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ItemListingPage(
              title: title,
              items: items,
              preparationId: widget.order.preparationLabel ?? '',
              orderNumber: orderNumber,
              order: widget.order,
              cubit: cubit,
              deliveryType: deliveryType,
            ),
      ),
    );
  }

  void _handleDeliveryTypeAction(
    BuildContext context,
    String title,
    String status,
    List<OrderItemModel> items,
    OrderDetailsCubit cubit,
    String deliveryType,
    String orderNumber,
  ) {
    if (status == 'cancel_request') {
      // Show cancel request info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title is already cancelled'),
          backgroundColor: Colors.grey,
        ),
      );
    } else {
      // Navigate to item list for picking
      _navigateToItemList(
        context,
        title,
        items,
        cubit,
        deliveryType,
        orderNumber,
      );
    }
  }

  Future<void> _handleEndPicking(
    BuildContext context,
    OrderDetailsLoaded state,
  ) async {
    // Check if there are unpicked items
    final filteredToPick =
        state.toPick.where((item) {
          bool shouldExclude = false;

          if (item.deliveryType == 'exp' &&
              state.expStatus == 'cancel_request') {
            shouldExclude = true;
          } else if (item.deliveryType == 'nol' &&
              state.nolStatus == 'cancel_request') {
            shouldExclude = true;
          } else if (item.deliveryType == 'war' &&
              state.warStatus == 'cancel_request') {
            shouldExclude = true;
          } else if (item.deliveryType == 'sup' &&
              state.supStatus == 'cancel_request') {
            shouldExclude = true;
          } else if (item.deliveryType == 'vpo' &&
              state.vpoStatus == 'cancel_request') {
            shouldExclude = true;
          }

          return !shouldExclude;
        }).toList();

    final hasUnpicked = filteredToPick.isNotEmpty;

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
                  onPressed: () => Navigator.pop(context),
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
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await BlocProvider.of<OrderDetailsCubit>(
          context,
        ).endPicking(orderNumber: '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Picking ended successfully.')),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error ending picking: $e')));
      }
    }
  }

  Future<void> _handleCustomerNotAnswering(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.phone_disabled, color: Colors.amber[700]),
                SizedBox(width: 8),
                Text(
                  'Customer Not Answering',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to mark this order as "Customer Not Answering"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                ),
                child: Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await BlocProvider.of<OrderDetailsCubit>(context).updateOrderStatus(
          status: 'customer_not_answer',
          reason: 'Customer not responding to calls',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to "Customer Not Answering"'),
              backgroundColor: Colors.amber[600],
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: ${e.toString()}'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancelRequest(BuildContext context) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const CancelReasonDialog(),
    );

    if (result == null) return;

    final cancelReason = result['reason'];
    final reasonId = result['reasonId'];

    if (cancelReason == null || reasonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid cancel reason selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Cancel Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to send a cancel request for the entire order?',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Reason:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cancelReason,
                        style: TextStyle(fontSize: 14, color: Colors.red[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Cancel Order'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await BlocProvider.of<OrderDetailsCubit>(
          context,
        ).cancelOrder(orderNumber: '', cancelReason: cancelReason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cancel request sent successfully with reason: $cancelReason',
              ),
              backgroundColor: Colors.orange[600],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  int _parsePreparationId(String preparationId) {
    try {
      return int.parse(preparationId);
    } catch (e) {
      return 0;
    }
  }
}
