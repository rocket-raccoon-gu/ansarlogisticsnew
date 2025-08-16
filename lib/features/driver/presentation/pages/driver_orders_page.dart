import 'dart:async';
import 'dart:developer';

import 'package:ansarlogisticsnew/features/driver/presentation/cubit/driver_orders_page_cubit.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/services/driver_location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import '../../data/models/driver_order_model.dart';
import '../widgets/driver_order_list_item.dart';
import 'driver_order_details_page.dart';
import 'driver_route_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  // Filter/Search State
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  bool _isFilterVisible = false;
  List<DriverOrderModel> _filteredOrders = [];
  bool _isSearching = false;
  bool _isFiltering = false;
  String? _selectedStatus;

  static const Map<String, String> _statusOptions = {
    'all': 'All Orders',
    'assigned_driver': 'Assigned Driver',
    'on_the_way': 'On The Way',
    'customer_not_answer': 'Customer Not Answer',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = getIt<DriverLocationService>();
    _initializeLocationStatus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _isFiltering = status != null && status != 'all';
      _isFilterVisible = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final hasSearchQuery = query.isNotEmpty;
    final hasStatusFilter = _selectedStatus != null && _selectedStatus != 'all';

    final cubit = context.read<DriverOrdersPageCubit>();
    final currentState = cubit.state;
    if (currentState is DriverOrdersPageLoaded) {
      List<DriverOrderModel> filtered = currentState.orders;

      // Apply status filter
      if (hasStatusFilter) {
        filtered =
            filtered
                .where(
                  (order) =>
                      order.driverStatus.toLowerCase() ==
                      _selectedStatus!.toLowerCase(),
                )
                .toList();
      }

      // Apply search filter (search by id, status, customer name)
      if (hasSearchQuery) {
        filtered =
            filtered.where((order) {
              return order.id.toLowerCase().contains(query) ||
                  order.driverStatus.toLowerCase().contains(query) ||
                  order.customer.name.toLowerCase().contains(query);
            }).toList();
      }

      setState(() {
        _filteredOrders = filtered;
        _isSearching = hasSearchQuery;
        _isFiltering = hasStatusFilter;
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _isSearching = false;
      _isFiltering = false;
      _filteredOrders = [];
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _isSearching = false;
        _applyFilters();
      }
    });
  }

  void _toggleFilter() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
      if (!_isFilterVisible) {
        _selectedStatus = null;
        _isFiltering = false;
        _applyFilters();
      }
    });
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
            _buildCustomAppBar(),
            if (_isSearchVisible) _buildSearchBar(),
            if (_isFilterVisible) _buildFilterBar(),
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
          final ordersToShow =
              (_isSearching || _isFiltering) ? _filteredOrders : state.orders;
          return Column(
            children: [
              // Route View Button
              if (ordersToShow.isNotEmpty) _buildRouteButton(),

              // Orders List
              Expanded(
                child:
                    ordersToShow.isEmpty
                        ? _buildEmptyState()
                        : _buildOrdersList(ordersToShow),
              ),
            ],
          );
        }
        return _buildLoadingState();
      },
    );
  }

  // Custom Modern App Bar
  Color _getAppBarColor(LocationTrackingStatus status) {
    switch (status) {
      case LocationTrackingStatus.tracking:
        return Colors.green[100]!;
      case LocationTrackingStatus.loading:
        return Colors.orange[100]!;
      case LocationTrackingStatus.idle:
        return Colors.blue[50]!;
    }
  }

  Widget _buildCustomAppBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getAppBarColor(_currentStatus),
        gradient: null, // Remove gradient for color animation
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _UsernameDisplay()),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Button
                  Container(
                    decoration: BoxDecoration(
                      color:
                          _isSearchVisible
                              ? Colors.blue[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSearchVisible ? Icons.close : Icons.search,
                        color:
                            _isSearchVisible
                                ? Colors.blue[700]
                                : Colors.grey[600],
                      ),
                      onPressed: _toggleSearch,
                      tooltip:
                          _isSearchVisible ? 'Close Search' : 'Search Orders',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter Button
                  Container(
                    decoration: BoxDecoration(
                      color:
                          _isFilterVisible
                              ? Colors.green[100]
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFilterVisible ? Icons.close : Icons.filter_list,
                        color:
                            _isFilterVisible
                                ? Colors.green[700]
                                : Colors.grey[600],
                      ),
                      onPressed: _toggleFilter,
                      tooltip:
                          _isFilterVisible
                              ? 'Close Filter'
                              : 'Filter by Status',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh Button
                  BlocBuilder<DriverOrdersPageCubit, DriverOrdersPageState>(
                    builder: (context, state) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          onPressed: () {
                            final cubit =
                                BlocProvider.of<DriverOrdersPageCubit>(context);
                            cubit.loadOrders();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLocationTrackingSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by Order ID, Status, or Customer',
          border: InputBorder.none,
          icon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _statusOptions.entries.map((entry) {
                  final isSelected = _selectedStatus == entry.key;
                  final statusColor =
                      entry.key == 'all'
                          ? Colors.grey
                          : (entry.key == 'assigned_driver'
                              ? Colors.orange
                              : entry.key == 'on_the_way'
                              ? Colors.blue
                              : entry.key == 'customer_not_answer'
                              ? Colors.red
                              : Colors.grey);
                  final statusIcon =
                      entry.key == 'all' ? Icons.list : Icons.circle;
                  return GestureDetector(
                    onTap: () => _onStatusChanged(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? statusColor.withOpacity(0.2)
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? statusColor : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: ${_selectedStatus != null ? _statusOptions[_selectedStatus!]! : 'All Orders'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Location Tracking Section
  Widget _buildLocationTrackingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            padding: const EdgeInsets.all(4),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.visible,
                maxLines: 2,
                softWrap: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
