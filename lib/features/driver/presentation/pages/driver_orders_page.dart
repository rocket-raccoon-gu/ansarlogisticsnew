import 'dart:async';
import 'dart:developer';

import 'package:ansarlogisticsnew/features/driver/presentation/cubit/driver_orders_page_cubit.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'dart:convert';
import '../../../../core/services/driver_location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/driver_order_model.dart';
import '../widgets/driver_order_list_item.dart';
import 'driver_order_details_page.dart';
import 'driver_route_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});

  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage> {
  late DriverLocationService _locationService;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _locationService = getIt<DriverLocationService>();
    _initializeLocationServiceWithTimeout();
  }

  Future<void> _initializeLocationServiceWithTimeout() async {
    try {
      // Add timeout to prevent hanging
      await _locationService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log("⚠️ Location service initialization timed out");
          throw TimeoutException('Location service initialization timed out');
        },
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = null;
        });
      }
    } catch (e) {
      log("❌ Error initializing location service: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DriverOrdersPageCubit>(),
      child: _DriverOrdersPageContent(
        isInitializing: _isInitializing,
        initError: _initError,
        onRetryInit: _initializeLocationServiceWithTimeout,
      ),
    );
  }
}

class _DriverOrdersPageContent extends StatefulWidget {
  final bool isInitializing;
  final String? initError;
  final VoidCallback onRetryInit;

  const _DriverOrdersPageContent({
    required this.isInitializing,
    this.initError,
    required this.onRetryInit,
  });

  @override
  State<_DriverOrdersPageContent> createState() =>
      _DriverOrdersPageContentState();
}

class _DriverOrdersPageContentState extends State<_DriverOrdersPageContent>
    with WidgetsBindingObserver {
  late DriverLocationService _locationService;
  LocationTrackingStatus _currentStatus = LocationTrackingStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = getIt<DriverLocationService>();
    _initializeLocationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Refresh status when app comes back to foreground
      _refreshLocationStatus();
    }
  }

  void _refreshLocationStatus() async {
    await _locationService.refreshStatus();
    if (mounted) {
      setState(() {
        _currentStatus = _locationService.status;
      });
    }
  }

  void _initializeLocationStatus() async {
    // Restore the tracking state from preferences
    await _locationService.restoreTrackingState();

    // Get the current status from the service
    setState(() {
      _currentStatus = _locationService.status;
    });

    // Listen to status changes
    _locationService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom Modern App Bar
            _buildCustomAppBar(),

            // Main Content
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // Show initialization error if any
    if (widget.initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Initialization Error',
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
                'Failed to initialize location services. This may affect location tracking.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onRetryInit,
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
    }

    // Show loading if still initializing
    if (widget.isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Show normal content
    return BlocBuilder<DriverOrdersPageCubit, DriverOrdersPageState>(
      builder: (context, state) {
        if (state is DriverOrdersPageLoaded) {
          final orders = state.orders;
          return Column(
            children: [
              // Route View Button
              if (orders.isNotEmpty) _buildRouteButton(),

              // Orders List
              Expanded(
                child:
                    orders.isEmpty
                        ? _buildEmptyState()
                        : _buildOrdersList(orders),
              ),
            ],
          );
        }
        return _buildLoadingState();
      },
    );
  }

  // Custom Modern App Bar
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row - Welcome and Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _UsernameDisplay(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: () {
                    // Use BlocProvider.of to get the cubit from the correct context
                    final cubit = BlocProvider.of<DriverOrdersPageCubit>(
                      context,
                    );
                    cubit.loadOrders();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Location Tracking Section
          _buildLocationTrackingSection(),
        ],
      ),
    );
  }

  // Location Tracking Section
  Widget _buildLocationTrackingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(_currentStatus).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(_currentStatus),
              color: _getStatusColor(_currentStatus),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(_currentStatus),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getStatusSubtitle(_currentStatus),
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          Container(
            decoration: BoxDecoration(
              color: _getStatusColor(_currentStatus),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _getStatusAction(_currentStatus),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                foregroundColor: Colors.black,
              ),
              child: Text(
                _getStatusButtonText(_currentStatus),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Route Button
  Widget _buildRouteButton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  // Get current orders from the BlocProvider
                  final cubit = BlocProvider.of<DriverOrdersPageCubit>(context);
                  final orders = cubit.orders;

                  // Validate that we have orders
                  if (orders.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'No orders available to show route.',
                        ),
                        backgroundColor: Colors.orange[400],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }

                  // Get current location
                  Position position = await Geolocator.getCurrentPosition();

                  log("🗺️ Opening route page");
                  log(
                    "📍 Driver location: ${position.latitude}, ${position.longitude}",
                  );
                  log("📦 Orders count: ${orders.length}");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DriverRoutePage(
                            orders: orders,
                            driverLocation: LatLng(
                              position.latitude,
                              position.longitude,
                            ),
                          ),
                    ),
                  );
                } catch (e) {
                  log("❌ Error opening route page: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not get current location: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red[400],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.route, size: 20),
              label: const Text(
                'View Route',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Orders List
  Widget _buildOrdersList(List<DriverOrderModel> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        final cubit = BlocProvider.of<DriverOrdersPageCubit>(context);
        cubit.loadOrders();
      },
      child: ListView.builder(
        // padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: DriverOrderListItem(
              order: order,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverOrderDetailsPage(order: order),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any orders assigned at the moment.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final cubit = BlocProvider.of<DriverOrdersPageCubit>(context);
              cubit.loadOrders();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Orders...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Helper methods for status
  Color _getStatusColor(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return Colors.green;
      case LocationTrackingStatus.loading:
        return Colors.orange;
      case LocationTrackingStatus.idle:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return Icons.location_on;
      case LocationTrackingStatus.loading:
        return Icons.location_searching;
      case LocationTrackingStatus.idle:
        return Icons.location_off;
    }
  }

  String _getStatusTitle(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return 'Location Tracking Active';
      case LocationTrackingStatus.loading:
        return 'Getting Location...';
      case LocationTrackingStatus.idle:
        return 'Location Tracking Inactive';
    }
  }

  String _getStatusSubtitle(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return 'Your location is being shared with the system';
      case LocationTrackingStatus.loading:
        return 'Please wait while we get your current location';
      case LocationTrackingStatus.idle:
        return 'Start tracking to share your location';
    }
  }

  String _getStatusButtonText(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return 'Stop';
      case LocationTrackingStatus.loading:
        return 'Wait';
      case LocationTrackingStatus.idle:
        return 'Start';
    }
  }

  VoidCallback? _getStatusAction(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return _locationService.stopTracking;
      case LocationTrackingStatus.loading:
        return () {
          Fluttertoast.showToast(
            msg: 'Your location is being fetched',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        };
      case LocationTrackingStatus.idle:
        return _locationService.startTracking;
    }
  }
}

// Separate widget for username display to avoid context issues
class _UsernameDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: UserStorageService.getUserName(),
      builder: (context, snapshot) {
        final username = snapshot.data ?? '';
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
