import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_details_model.dart';
import '../../data/models/order_model.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/category_item_list.dart';
import '../cubit/order_details_cubit.dart';
import 'order_item_details_page.dart';
import 'package:ansarlogisticsnew/core/services/user_storage_service.dart';
import 'order_details_page.dart';
import 'picker_orders_page.dart';
import '../cubit/picker_orders_cubit.dart';

class ItemListingPage extends StatefulWidget {
  final List<OrderItemModel> items;
  final String? title;
  final OrderDetailsCubit? cubit;
  final String? deliveryType;
  final int? tabIndex;
  final int preparationId;
  final String orderNumber;
  final OrderModel order;

  const ItemListingPage({
    Key? key,
    required this.items,
    this.title,
    this.cubit,
    this.deliveryType,
    this.tabIndex,
    required this.preparationId,
    required this.orderNumber,
    required this.order,
  }) : super(key: key);

  @override
  State<ItemListingPage> createState() => _ItemListingPageState();
}

class _ItemListingPageState extends State<ItemListingPage> {
  int _selectedIndex = 0;
  String? _selectedDeliveryType;

  @override
  void initState() {
    super.initState();
    if (widget.tabIndex != null) {
      _selectedIndex = widget.tabIndex!;
    }
    if (widget.deliveryType != null) {
      _selectedDeliveryType = widget.deliveryType;
    }
  }

  List<OrderItemModel> _getFilteredItems(List<OrderItemModel> allItems) {
    List<OrderItemModel> filtered = allItems;
    if (_selectedDeliveryType != null) {
      filtered =
          filtered
              .where((item) => item.deliveryType == _selectedDeliveryType)
              .toList();
    }
    switch (_selectedIndex) {
      case 0:
        return filtered
            .where((item) => item.status == OrderItemStatus.toPick)
            .toList();
      case 1:
        return filtered
            .where((item) => item.status == OrderItemStatus.picked)
            .toList();
      case 2:
        return filtered
            .where((item) => item.status == OrderItemStatus.holded)
            .toList();
      case 3:
        return filtered
            .where((item) => item.status == OrderItemStatus.itemNotAvailable)
            .toList();
      default:
        return filtered;
    }
  }

  List<CategoryItemModel> _getFilteredCategories(
    List<CategoryItemModel> allCategories,
  ) {
    List<CategoryItemModel> filteredCategories = allCategories;
    if (_selectedDeliveryType != null) {
      filteredCategories =
          allCategories
              .map(
                (category) => CategoryItemModel(
                  category: category.category,
                  items:
                      category.items
                          .where(
                            (item) =>
                                item.deliveryType == _selectedDeliveryType,
                          )
                          .toList(),
                ),
              )
              .where((category) => category.items.isNotEmpty)
              .toList();
    }
    switch (_selectedIndex) {
      case 0:
        return filteredCategories
            .map((category) {
              return CategoryItemModel(
                category: category.category,
                items:
                    category.items
                        .where((item) => item.status == OrderItemStatus.toPick)
                        .toList(),
              );
            })
            .where((category) => category.items.isNotEmpty)
            .toList();
      case 1:
        return filteredCategories
            .map((category) {
              return CategoryItemModel(
                category: category.category,
                items:
                    category.items
                        .where((item) => item.status == OrderItemStatus.picked)
                        .toList(),
              );
            })
            .where((category) => category.items.isNotEmpty)
            .toList();
      case 2:
        return filteredCategories
            .map((category) {
              return CategoryItemModel(
                category: category.category,
                items:
                    category.items
                        .where((item) => item.status == OrderItemStatus.holded)
                        .toList(),
              );
            })
            .where((category) => category.items.isNotEmpty)
            .toList();
      case 3:
        return filteredCategories
            .map((category) {
              return CategoryItemModel(
                category: category.category,
                items:
                    category.items
                        .where(
                          (item) =>
                              item.status == OrderItemStatus.itemNotAvailable,
                        )
                        .toList(),
              );
            })
            .where((category) => category.items.isNotEmpty)
            .toList();
      default:
        return filteredCategories;
    }
  }

  String get _emptyText {
    switch (_selectedIndex) {
      case 0:
        return 'No items to pick';
      case 1:
        return 'No picked items';
      case 2:
        return 'No on hold items';
      case 3:
        return 'No unavailable items';
      default:
        return 'No items';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cubit, use BlocBuilder to listen for state changes
    if (widget.cubit != null) {
      return BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
        bloc: widget.cubit,
        builder: (context, state) {
          if (state is OrderDetailsLoaded) {
            // Filter the cubit's categories to only include items that match the passed items' delivery types
            final passedItemsDeliveryTypes =
                widget.items.map((item) => item.deliveryType).toSet();

            final filteredCategories =
                state.categories
                    .map((category) {
                      // Filter items in this category to only include those matching the passed items' delivery types
                      final filteredItems =
                          category.items
                              .where(
                                (item) => passedItemsDeliveryTypes.contains(
                                  item.deliveryType,
                                ),
                              )
                              .toList();

                      return CategoryItemModel(
                        category: category.category,
                        items: filteredItems,
                      );
                    })
                    .where((category) => category.items.isNotEmpty)
                    .toList();

            // Further filter by the selected tab (To Pick, Picked, etc.)
            final tabFilteredCategories = _getFilteredCategories(
              filteredCategories,
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title ?? 'Items'),
                actions: [
                  TextButton.icon(
                    icon: Icon(Icons.cancel_schedule_send, color: Colors.red),
                    label: Text(
                      'Cancel Request',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('Cancel Request'),
                              content: Text(
                                'Are you sure you want to send a cancel request for this order?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                    // Navigator.pop(context);
                                    log(widget.orderNumber);
                                  },
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
                          await widget.cubit!.cancelOrder(
                            orderNumber: widget.orderNumber,
                          );
                          if (mounted) {
                            // Show toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cancel request sent successfully.',
                                ),
                              ),
                            );
                            // Navigate to OrderDetailsPage and on pop, go to PickerOrdersPage
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => OrderDetailsPage(
                                          order: widget.order,
                                        ),
                                  ),
                                )
                                .then((_) {
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
                                });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              body:
                  tabFilteredCategories.isEmpty
                      ? Center(child: Text(_emptyText))
                      : CategoryItemList(
                        categories: tabFilteredCategories,
                        cubit: widget.cubit,
                        preparationId: widget.preparationId,
                        order: widget.order,
                      ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed:
                    () => _showAddItemSheet(widget.cubit!, widget.orderNumber),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                backgroundColor: Colors.blue,
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt),
                    label: 'To Pick',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.check_circle_outline),
                    label: 'Picked',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.pause_circle_outline),
                    label: 'On Hold',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.remove_circle_outline),
                    label: 'Not Available',
                  ),
                ],
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
              ),
            );
          } else if (state is OrderDetailsLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            // Fallback to original behavior if no cubit provided
            final filteredItems = _getFilteredItems(widget.items);
            return _buildScaffoldWithItems(filteredItems);
          }
        },
      );
    } else {
      // Fallback to items list if no cubit available
      final filteredItems = _getFilteredItems(widget.items);
      return _buildScaffoldWithItems(filteredItems);
    }
  }

  Widget _buildScaffoldWithItems(List<OrderItemModel> filteredItems) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Items')),
      body:
          filteredItems.isEmpty
              ? Center(child: Text(_emptyText))
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final int prepId =
                      widget.cubit!.orderId is int
                          ? widget.cubit!.orderId as int
                          : int.tryParse(widget.cubit!.orderId.toString()) ?? 0;
                  return OrderItemTile(
                    item: item,
                    onTap: () {
                      if (widget.cubit != null) {
                        _handleOrderItemTap(context, item, prepId);
                      }
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(widget.cubit!, widget.orderNumber),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'To Pick'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Picked',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pause_circle_outline),
            label: 'On Hold',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_circle_outline),
            label: 'Not Available',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Future<void> _showAddItemSheet(
    OrderDetailsCubit cubit,
    String orderNumber,
  ) async {
    final result = await Navigator.pushNamed(
      context,
      '/item_add_page',
      arguments: {
        'preparationId': widget.preparationId,
        'cubit': widget.cubit,
        'orderNumber': orderNumber,
      },
    );
    if (result == 'added') {
      widget.cubit?.loadItems();
      setState(() {
        _selectedIndex = 1; // Switch to Picked tab
      });
    }
  }

  void _handleOrderItemTap(
    BuildContext context,
    OrderItemModel item,
    int prepId,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OrderItemDetailsPage(
              item: item,
              cubit: widget.cubit!,
              preparationId: prepId,
              order: widget.order, // <-- pass the order here
            ),
      ),
    );
    if (result == 'updated' ||
        result == 'added' ||
        result == 'replaced' ||
        result == 'holded') {
      await widget.cubit!.reloadItemsFromApi();
      setState(() {
        if (result == 'added' || result == 'replaced') {
          _selectedIndex = 1; // Switch to Picked tab
        }
        if (result == 'holded') {
          _selectedIndex = 2; // Switch to On Hold tab
        }
      });
    }
  }
}
