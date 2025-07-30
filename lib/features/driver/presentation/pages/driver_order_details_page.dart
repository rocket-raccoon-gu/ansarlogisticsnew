import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ansarlogisticsnew/core/constants/app_strings.dart';
import '../../data/models/driver_order_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/driver_order_details_cubit.dart';
import '../../../../core/services/user_storage_service.dart';
import '../../../../core/services/call_logs_service.dart';
import 'package:ansarlogisticsnew/features/navigation/presentation/pages/role_based_navigation_page.dart';
import 'package:ansarlogisticsnew/features/navigation/presentation/cubit/bottom_navigation_cubit.dart';
import 'bill_upload_page.dart';
import 'dart:developer';

class DriverOrderDetailsPage extends StatefulWidget {
  final DriverOrderModel order;
  const DriverOrderDetailsPage({super.key, required this.order});

  @override
  State<DriverOrderDetailsPage> createState() => _DriverOrderDetailsPageState();
}

class _DriverOrderDetailsPageState extends State<DriverOrderDetailsPage> {
  late DriverOrderDetailsCubit _cubit;
  String? _token;

  @override
  void initState() {
    super.initState();
    _cubit = DriverOrderDetailsCubit();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final user = await UserStorageService.getUserData();
    final token = user?.token;
    if (token != null) {
      setState(() => _token = token);
      _cubit.fetchOrderDetails(widget.order.id, token);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _launchPhone(String phone) async {
    CallLogs c1 = CallLogs();
    await c1.handleCall(phone, () async {
      log("📞 Call initiated for driver order: ${widget.order.id}");
    });
  }

  void _launchWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text('Order #${widget.order.id}')),
        body: BlocBuilder<DriverOrderDetailsCubit, DriverOrderDetailsState>(
          builder: (context, state) {
            if (state is DriverOrderOnTheWaySuccess) {
              // Navigate to main navigation and select driver orders tab
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order marked as ${state.orderStatus}!'),
                  ),
                );
                // Small delay to ensure state is properly updated
                Future.delayed(const Duration(milliseconds: 500), () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder:
                          (_) => const RoleBasedNavigationPage(
                            userRole: UserRole.driver,
                          ),
                    ),
                    (route) => false,
                  );
                });
              });
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DriverOrderDetailsLoading || _token == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Updating order status...'),
                  ],
                ),
              );
            }
            if (state is DriverOrderDetailsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Retry the operation
                        if (_token != null) {
                          _cubit.fetchOrderDetails(widget.order.id, _token!);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is DriverOrderDetailsLoaded) {
              final details = state.details.data;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Payment Mode:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      details.order.paymentMode,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order Total:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'QAR ${details.order.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              // Show delivered status if order is delivered
                              if (widget.order.driverStatus == 'delivered') ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Order Delivered Successfully',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Divider(),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    details.customer.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    details.customer.mobileNumber,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Call',
                                    onPressed:
                                        () => _launchPhone(
                                          details.customer.mobileNumber,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'WhatsApp',
                                    onPressed:
                                        () => _launchWhatsApp(
                                          details.customer.mobileNumber,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      details.address.zone,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.home,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      details.address.street,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Only show Customer Not Answering button if order is not delivered
                              if (widget.order.driverStatus != 'delivered')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.phone_disabled,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Customer Not Answering',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {
                                        _cubit.updateOrderStatusDriver(
                                          _token!,
                                          widget.order.id,
                                          'customer_not_answering',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Order Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: details.items.length,
                          separatorBuilder:
                              (context, index) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = details.items[index];
                            return ListTile(
                              title: Text(
                                item.name,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text('Qty: ${item.quantity}'),
                              trailing: Text(
                                'QAR ${item.total.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<
              DriverOrderDetailsCubit,
              DriverOrderDetailsState
            >(
              builder: (context, state) {
                final isLoading = state is DriverOrderDetailsLoading;
                final isOnTheWay = widget.order.driverStatus == 'on_the_way';
                final isDelivered = widget.order.driverStatus == 'delivered';

                // Don't show any bottom navigation bar if order is delivered
                if (isDelivered) {
                  return const SizedBox.shrink();
                }

                if (isOnTheWay) {
                  // Show Upload Bill button when order is on the way
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BillUploadPage(order: widget.order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text(
                        'Upload Bill',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Show Mark as On the Way button for other statuses
                  return GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (!isLoading) {
                        _cubit.updateOrderStatusDriver(
                          _token!,
                          widget.order.id,
                          'on_the_way',
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isLoading ? Colors.grey : Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child:
                          isLoading
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Updating...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                'Mark as On the Way',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
