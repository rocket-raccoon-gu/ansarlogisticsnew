import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/user_storage_service.dart';
import '../cubit/picker_orders_cubit.dart';
import '../widgets/order_list_item_widget.dart';
import 'order_details_page.dart';
import 'dart:developer';

class PickerOrdersPage extends StatefulWidget {
  const PickerOrdersPage({super.key});

  @override
  State<PickerOrdersPage> createState() => _PickerOrdersPageState();
}

class _PickerOrdersPageState extends State<PickerOrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  bool _isFilterVisible = false;
  List<dynamic> _filteredOrders = [];
  bool _isSearching = false;
  bool _isFiltering = false;
  String? _selectedStatus;

  // Define available statuses for filtering
  static const Map<String, String> _statusOptions = {
    'all': 'All Orders',
    'assigned_picker': 'Assigned to Picker',
    'start_picking': 'Start Picking',
    'end_picking': 'End Picking',
    'material_request': 'Material Request',
  };

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned_picker':
        return Colors.orange;
      case 'start_picking':
        return Colors.green;
      case 'end_picking':
        return Colors.purple;
      case 'material_request':
        return Colors.teal;
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'assigned_picker':
        return Icons.assignment;
      case 'start_picking':
        return Icons.play_circle;
      case 'end_picking':
        return Icons.check_circle;
      case 'material_request':
        return Icons.inventory;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
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
      // Auto-hide filter bar after selection
      _isFilterVisible = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final hasSearchQuery = query.isNotEmpty;
    final hasStatusFilter = _selectedStatus != null && _selectedStatus != 'all';

    // Get current orders from cubit
    final currentState = context.read<PickerOrdersCubit>().state;
    if (currentState is PickerOrdersLoaded) {
      List<dynamic> filtered = currentState.orders;

      // Apply status filter
      if (hasStatusFilter) {
        filtered =
            filtered.where((order) {
              return order.status.toLowerCase() ==
                  _selectedStatus!.toLowerCase();
            }).toList();
      }

      // Apply search filter
      if (hasSearchQuery) {
        filtered =
            filtered.where((order) {
              return (order.preparationLabel ?? '').toLowerCase().contains(
                    query,
                  ) ||
                  order.status.toLowerCase().contains(query) ||
                  (order.timerange?.toLowerCase().contains(query) ?? false) ||
                  order.customerFirstname.toLowerCase().contains(query) ||
                  order.customerEmail.toLowerCase().contains(query);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom Modern App Bar
            _buildCustomAppBar(),

            // Search Bar (when visible)
            if (_isSearchVisible) _buildSearchBar(),

            // Filter Bar (when visible)
            if (_isFilterVisible) _buildFilterBar(),

            // Main Content
            Expanded(
              child: BlocBuilder<PickerOrdersCubit, PickerOrdersState>(
                builder: (context, state) {
                  if (state is PickerOrdersLoading) {
                    return _buildLoadingState();
                  }

                  if (state is PickerOrdersRefreshing) {
                    return _buildRefreshingState(state);
                  }

                  if (state is PickerOrdersError) {
                    return _buildErrorState(state);
                  }

                  if (state is PickerOrdersLoaded) {
                    final ordersToShow =
                        (_isSearching || _isFiltering)
                            ? _filteredOrders
                            : state.orders;

                    if (ordersToShow.isEmpty) {
                      return _buildEmptyState(
                        state.orders.isEmpty && !_isSearching && !_isFiltering,
                      );
                    }

                    return _buildOrdersList(ordersToShow);
                  }

                  return _buildInitialState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Modern App Bar
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row - Welcome and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FutureBuilder<String?>(
                  future: UserStorageService.getUserName(),
                  builder: (context, snapshot) {
                    final username = snapshot.data ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    username.isNotEmpty ? username : 'Picker',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            // Removed version text as per edit hint
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
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
                  BlocBuilder<PickerOrdersCubit, PickerOrdersState>(
                    builder: (context, state) {
                      final isRefreshing = state is PickerOrdersRefreshing;
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isRefreshing
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon:
                              isRefreshing
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue[700]!,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.refresh,
                                    color: Colors.grey,
                                  ),
                          onPressed:
                              isRefreshing
                                  ? null
                                  : () {
                                    context
                                        .read<PickerOrdersCubit>()
                                        .refreshOrders();
                                  },
                          tooltip:
                              isRefreshing ? 'Refreshing...' : 'Refresh Orders',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Stats Row
          _buildStatsRow(),
        ],
      ),
    );
  }

  // Stats Row
  Widget _buildStatsRow() {
    return BlocBuilder<PickerOrdersCubit, PickerOrdersState>(
      builder: (context, state) {
        if (state is PickerOrdersLoaded) {
          final ordersToCount =
              (_isSearching || _isFiltering) ? _filteredOrders : state.orders;

          final totalOrders = ordersToCount.length;
          final assignedOrders =
              ordersToCount.where((o) => o.status == 'assigned_picker').length;
          final inProgressOrders =
              ordersToCount.where((o) => o.status == 'start_picking').length;
          final endPickingOrders =
              ordersToCount.where((o) => o.status == 'end_picking').length;
          final materialRequestOrders =
              ordersToCount.where((o) => o.status == 'material_request').length;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      totalOrders.toString(),
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Assigned',
                      assignedOrders.toString(),
                      _getStatusIcon('assigned_picker'),
                      _getStatusColor('assigned_picker'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'In Progress',
                      inProgressOrders.toString(),
                      _getStatusIcon('start_picking'),
                      _getStatusColor('start_picking'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Stat Card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        decoration: InputDecoration(
          hintText: 'Search orders by ID, status, or time range...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // Filter Bar
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
                          : _getStatusColor(entry.key);
                  final statusIcon =
                      entry.key == 'all'
                          ? Icons.list
                          : _getStatusIcon(entry.key);

                  return GestureDetector(
                    onTap: () => _onStatusChanged(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? statusColor.withOpacity(0.2)
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? statusColor : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : statusIcon,
                            size: 16,
                            color: isSelected ? statusColor : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color:
                                  isSelected ? statusColor : Colors.grey[700],
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
                'Selected: ${_selectedStatus != null ? _statusOptions[_selectedStatus]! : 'All Orders'}',
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

  // Active Filters Indicator
  Widget _buildActiveFiltersIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isSearching && _isFiltering
                    ? Icons.search
                    : _isSearching
                    ? Icons.search
                    : Icons.filter_list,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isSearching && _isFiltering
                      ? 'Search & Filter Active'
                      : _isSearching
                      ? 'Search Active'
                      : 'Filter Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              Text(
                'Status: ${_statusOptions[_selectedStatus] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_filteredOrders.length} results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),

          if (_isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Search: "${_searchController.text}"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Loading State
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Refreshing State
  Widget _buildRefreshingState(PickerOrdersRefreshing state) {
    final ordersToShow =
        (_isSearching || _isFiltering) ? _filteredOrders : state.orders;

    if (ordersToShow.isEmpty) {
      return _buildEmptyState(
        state.orders.isEmpty && !_isSearching && !_isFiltering,
      );
    }

    return Column(
      children: [
        // Refresh indicator at the top
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Refreshing orders...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        // Orders list with existing data
        Expanded(child: _buildOrdersList(ordersToShow)),
      ],
    );
  }

  // Error State
  Widget _buildErrorState(PickerOrdersError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PickerOrdersCubit>().refreshOrders();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isNoOrders) {
    final hasFilters = _isSearching || _isFiltering;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isNoOrders ? Colors.grey[100] : Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNoOrders ? Icons.shopping_cart : Icons.search_off,
              size: 60,
              color: isNoOrders ? Colors.grey[400] : Colors.blue[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNoOrders
                ? 'No Orders Available'
                : hasFilters
                ? 'No Matching Orders'
                : 'No Search Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isNoOrders ? Colors.grey[600] : Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isNoOrders
                  ? 'You don\'t have any picker orders assigned yet. Check back later!'
                  : hasFilters
                  ? 'No orders match your current filters. Try adjusting your search criteria or status filter.'
                  : 'No orders match your search criteria. Try different keywords.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasFilters) ...[
                ElevatedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
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
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  if (isNoOrders) {
                    context.read<PickerOrdersCubit>().refreshOrders();
                  } else {
                    _clearAllFilters();
                  }
                },
                icon: Icon(isNoOrders ? Icons.refresh : Icons.clear),
                label: Text(isNoOrders ? 'Refresh' : 'Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isNoOrders ? Colors.grey[600] : Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Orders List
  Widget _buildOrdersList(List<dynamic> orders) {
    return BlocBuilder<PickerOrdersCubit, PickerOrdersState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<PickerOrdersCubit>().refreshOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderListItemWidget(
                order: order,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(order: order),
                    ),
                  );
                },
                onStatusUpdated: () {
                  context.read<PickerOrdersCubit>().refreshOrders();
                },
              );
            },
          ),
        );
      },
    );
  }

  // Initial State
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.pickerOrders,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your picker orders will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
