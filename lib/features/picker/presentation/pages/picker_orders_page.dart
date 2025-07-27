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
  List<dynamic> _filteredOrders = [];
  bool _isSearching = false;

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
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredOrders = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Get current orders from cubit
    final currentState = context.read<PickerOrdersCubit>().state;
    if (currentState is PickerOrdersLoaded) {
      final filtered =
          currentState.orders.where((order) {
            return order.preparationId.toLowerCase().contains(query) ||
                order.status.toLowerCase().contains(query) ||
                (order.timerange?.toLowerCase().contains(query) ?? false);
          }).toList();

      setState(() {
        _filteredOrders = filtered;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _isSearching = false;
        _filteredOrders = [];
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

            // Main Content
            Expanded(
              child: BlocBuilder<PickerOrdersCubit, PickerOrdersState>(
                builder: (context, state) {
                  if (state is PickerOrdersLoading) {
                    return _buildLoadingState();
                  }

                  if (state is PickerOrdersError) {
                    return _buildErrorState(state);
                  }

                  if (state is PickerOrdersLoaded) {
                    final ordersToShow =
                        _isSearching ? _filteredOrders : state.orders;

                    if (ordersToShow.isEmpty) {
                      return _buildEmptyState(state.orders.isEmpty);
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
      padding: const EdgeInsets.all(20),
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
              FutureBuilder<String?>(
                future: UserStorageService.getUserName(),
                builder: (context, snapshot) {
                  final username = snapshot.data ?? '';
                  return Column(
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  );
                },
              ),
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
                  // Refresh Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      onPressed: () {
                        context.read<PickerOrdersCubit>().refreshOrders();
                      },
                      tooltip: 'Refresh Orders',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

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
          final totalOrders = state.orders.length;
          final assignedOrders =
              state.orders.where((o) => o.status == 'assigned_picker').length;
          final inProgressOrders =
              state.orders.where((o) => o.status == 'start_picking').length;

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Assigned',
                  assignedOrders.toString(),
                  Icons.assignment,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  inProgressOrders.toString(),
                  Icons.play_circle,
                  Colors.green,
                ),
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
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
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
            isNoOrders ? 'No Orders Available' : 'No Search Results',
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
                  : 'No orders match your search criteria. Try different keywords.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (isNoOrders) {
                context.read<PickerOrdersCubit>().refreshOrders();
              } else {
                _searchController.clear();
              }
            },
            icon: Icon(isNoOrders ? Icons.refresh : Icons.clear),
            label: Text(isNoOrders ? 'Refresh' : 'Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isNoOrders ? Colors.grey[600] : Colors.blue[600],
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

  // Orders List
  Widget _buildOrdersList(List<dynamic> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PickerOrdersCubit>().refreshOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
