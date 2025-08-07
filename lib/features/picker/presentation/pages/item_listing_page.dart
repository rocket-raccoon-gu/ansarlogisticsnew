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
import 'package:ansarlogisticsnew/features/navigation/presentation/pages/main_navigation_page.dart';

class ItemListingPage extends StatefulWidget {
  final List<OrderItemModel> items;
  final String? title;
  final OrderDetailsCubit? cubit;
  final String? deliveryType;
  final int? tabIndex;
  final String preparationId;
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
  List<OrderItemModel> filteredItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.tabIndex != null) {
      _selectedIndex = widget.tabIndex!;
    }
    if (widget.deliveryType != null) {
      _selectedDeliveryType = widget.deliveryType;
    }

    // Debug logging for initialization
    print('🔍 ItemListingPage - initState called:');
    print('  - widget.deliveryType: ${widget.deliveryType}');
    print('  - _selectedDeliveryType: $_selectedDeliveryType');
    print('  - widget.items.length: ${widget.items.length}');
    print('  - widget.items delivery type breakdown:');
    for (var item in widget.items) {
      print('    - ${item.name}: deliveryType = ${item.deliveryType}');
    }
  }

  List<OrderItemModel> _getFilteredItems(List<OrderItemModel> allItems) {
    List<OrderItemModel> filtered = allItems;

    // Additional filtering by delivery type if specified
    if (widget.deliveryType != null) {
      filtered =
          filtered
              .where((item) => item.deliveryType == widget.deliveryType)
              .toList();
      print(
        '🔍 ItemListingPage - After delivery type filtering: ${filtered.length} items',
      );
    }

    // Debug logging for filtering
    print('🔍 ItemListingPage - _getFilteredItems called:');
    print('  - _selectedIndex: $_selectedIndex');
    print('  - widget.deliveryType: ${widget.deliveryType}');
    print('  - allItems.length: ${allItems.length}');
    print('  - allItems status breakdown:');
    for (var item in allItems) {
      print(
        '    - ${item.name}: ${item.status} (deliveryType: ${item.deliveryType})',
      );
    }

    switch (_selectedIndex) {
      case 0:
        final toPickItems =
            filtered
                .where((item) => item.status == OrderItemStatus.toPick)
                .where((item) => item.quantity != 0)
                .toList();
        print('🔍 ItemListingPage - To Pick tab: ${toPickItems.length} items');
        for (var item in toPickItems) {
          print(
            '    - ${item.name}: status=${item.status}, qty=${item.quantity}',
          );
        }
        return toPickItems;
      case 1:
        return filtered
            .where((item) => item.status == OrderItemStatus.picked)
            .toList();
      case 2:
        return filtered
            .where((item) => item.status == OrderItemStatus.holded)
            .toList();
      case 3:
        // Show both not available and canceled items in Not Available tab
        return filtered
            .where(
              (item) =>
                  item.status == OrderItemStatus.itemNotAvailable ||
                  item.status == OrderItemStatus.canceled,
            )
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
                        .where((item) => item.quantity != 0)
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
                              item.status == OrderItemStatus.itemNotAvailable ||
                              item.status == OrderItemStatus.canceled,
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

  bool checkList(List<OrderItemModel> allItems) {
    return allItems.any((item) => item.status == OrderItemStatus.toPick);
  }

  bool _isToPickTabEmpty() {
    final toPickItems =
        widget.items
            .where((item) => item.status == OrderItemStatus.toPick)
            .toList();
    return toPickItems.isEmpty;
  }

  List<CategoryItemModel> filteredCategories = [];

  @override
  Widget build(BuildContext context) {
    // Debug logging for items passed to ItemListingPage
    print('🔍 ItemListingPage - build called:');
    print('  - widget.items.length: ${widget.items.length}');
    print('  - widget.deliveryType: ${widget.deliveryType}');
    print('  - widget.title: ${widget.title}');
    print('  - widget.order.status: ${widget.order.status}');
    print('  - widget.cubit != null: ${widget.cubit != null}');
    print('  - widget.deliveryType: ${widget.deliveryType}');
    print(
      '  - Should show FAB: ${widget.cubit != null && widget.order.status == 'start_picking'}',
    );
    print('  - widget.items status breakdown:');
    for (var item in widget.items) {
      print(
        '    - ${item.name}: ${item.status} (deliveryType: ${item.deliveryType})',
      );
    }

    // If we have a cubit, use BlocBuilder to listen for state changes
    if (widget.cubit != null) {
      return BlocBuilder<OrderDetailsCubit, OrderDetailsState>(
        bloc: widget.cubit,
        builder: (context, state) {
          if (state is OrderDetailsLoaded) {
            // Use the cubit's categories but filter them to only include items that match the delivery type

            if (widget.deliveryType != null) {
              // Use delivery-type-specific categories based on the delivery type
              switch (widget.deliveryType) {
                case 'exp':
                  filteredCategories = state.expressCategories;
                  break;
                case 'nol':
                  filteredCategories = state.normalCategories;
                  break;
                case 'war':
                  filteredCategories = state.warehouseCategories;
                  break;
                case 'sup':
                  filteredCategories = state.supplierCategories;
                  break;
                case 'vpo':
                  filteredCategories = state.vendorPickupCategories;
                  break;
                case 'aby':
                  filteredCategories = state.abayaCategories;
                  break;
                default:
                  // Fallback to filtering general categories
                  filteredCategories =
                      state.categories
                          .map((category) {
                            final filteredItems =
                                category.items
                                    .where(
                                      (item) =>
                                          item.deliveryType ==
                                          widget.deliveryType,
                                    )
                                    .where((item) => item.quantity != 0)
                                    .toList();

                            return CategoryItemModel(
                              category: category.category,
                              items: filteredItems,
                            );
                          })
                          .where((category) => category.items.isNotEmpty)
                          .toList();
              }

              // Debug logging for category filtering
              print(
                '🔍 ItemListingPage - Delivery Type: ${widget.deliveryType}',
              );
              print(
                '🔍 ItemListingPage - Filtered categories: ${filteredCategories.length}',
              );
              for (var category in filteredCategories) {
                print(
                  '  - Category: ${category.category}, Items: ${category.items.length}',
                );
                for (var item in category.items) {
                  print('    - ${item.name}: ${item.deliveryType}');
                }
              }
            } else {
              // If no delivery type specified, use all categories
              filteredCategories = state.categories;
            }

            // Further filter by the selected tab (To Pick, Picked, etc.)
            final tabFilteredCategories = _getFilteredCategories(
              filteredCategories,
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.preparationId,
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton.icon(
                    icon: Icon(Icons.cancel_schedule_send, color: Colors.red),
                    label: Text(
                      'Cancel Req',
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
                          if (widget.cubit != null) {
                            log(
                              '🔍 ItemListingPage - orderNumber: ${widget.orderNumber}',
                            );

                            //   String modifiedOrderNumber = widget.orderNumber;

                            //   // Check if order number starts with PREN
                            //   if (widget.orderNumber.startsWith('PREN')) {
                            //     // Modify order number based on delivery type
                            //     if (widget.deliveryType == 'exp') {
                            //       // Replace PREN with PREXP for express orders
                            //       modifiedOrderNumber = widget.orderNumber
                            //           .replaceFirst('PREN', 'PREXP');
                            //     } else if (widget.deliveryType == 'nol') {
                            //       // Replace PREN with PRNOL for normal orders
                            //       modifiedOrderNumber = widget.orderNumber
                            //           .replaceFirst('PREN', 'PRNOL');
                            //     }
                            //     // For other delivery types, keep the original PREN
                            //   }
                            //   // If order number doesn't start with PREN, use original order number

                            await widget.cubit!.cancelOrder(
                              orderNumber: widget.orderNumber,
                            );
                          }
                          if (mounted) {
                            // Show toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cancel request sent successfully.',
                                ),
                              ),
                            );
                            // Navigate directly to MainNavigationPage
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder:
                                    (context) => const MainNavigationPage(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
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
              floatingActionButton:
                  widget.cubit != null && widget.order.status == 'start_picking'
                      ? FloatingActionButton.extended(
                        onPressed:
                            () => _showAddItemSheet(
                              widget.cubit!,
                              widget.orderNumber,
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        backgroundColor: Colors.blue,
                      )
                      : null,
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
              bottomSheet:
                  _selectedIndex == 1 && _isToPickTabEmpty()
                      ? Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: SafeArea(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Finish Picking',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                print(
                                  '🔍 Finish Picking - orderNumber: ${widget.orderNumber}',
                                );
                                print(
                                  '🔍 Finish Picking - orderNumber.isEmpty: ${widget.orderNumber.isEmpty}',
                                );

                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text('Finish Picking'),
                                        content: Text(
                                          'Are you sure you want to finish picking for this order?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: Text('No'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: Text('Yes'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
                                  try {
                                    if (widget.orderNumber.isNotEmpty) {
                                      await widget.cubit!.endPicking(
                                        orderNumber: widget.orderNumber,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Picking ended successfully.',
                                            ),
                                          ),
                                        );
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const MainNavigationPage(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: Order number is missing.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error ending picking: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      )
                      : null,
            );
          } else if (state is OrderDetailsLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            // Fallback to original behavior if no cubit provided
            filteredItems = _getFilteredItems(widget.items);
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
    // Debug logging for fallback scaffold
    print('🔍 ItemListingPage - _buildScaffoldWithItems called:');
    print('  - widget.order.status: ${widget.order.status}');
    print('  - widget.cubit != null: ${widget.cubit != null}');
    print(
      '  - Should show FAB: ${widget.cubit != null && widget.order.status == 'start_picking'}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "#${widget.preparationId}",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.cancel_schedule_send, color: Colors.red),
            label: Text(
              'Cancel Req',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                  if (widget.cubit != null) {
                    String modifiedOrderNumber = widget.orderNumber;

                    // Check if order number starts with PREN
                    if (widget.orderNumber.startsWith('PREN')) {
                      // Modify order number based on delivery type
                      if (widget.deliveryType == 'exp') {
                        // Replace PREN with PREXP for express orders
                        modifiedOrderNumber = widget.orderNumber.replaceFirst(
                          'PREN',
                          'PREXP',
                        );
                      } else if (widget.deliveryType == 'nol') {
                        // Replace PREN with PRNOL for normal orders
                        modifiedOrderNumber = widget.orderNumber.replaceFirst(
                          'PREN',
                          'PRNOL',
                        );
                      }
                      // For other delivery types, keep the original PREN
                    }
                    // If order number doesn't start with PREN, use original order number

                    await widget.cubit!.cancelOrder(
                      orderNumber: modifiedOrderNumber,
                    );
                  }
                  if (mounted) {
                    // Show toast
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cancel request sent successfully.'),
                      ),
                    );
                    // Navigate directly to MainNavigationPage
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationPage(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body:
          filteredItems.isEmpty
              ? Center(child: Text(_emptyText))
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final String prepId =
                      widget.cubit?.orderId.toString() ?? widget.preparationId;
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
      floatingActionButton:
          widget.cubit != null && widget.order.status == 'start_picking'
              ? FloatingActionButton.extended(
                onPressed:
                    () => _showAddItemSheet(widget.cubit!, widget.orderNumber),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                backgroundColor: Colors.blue,
              )
              : null,
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
    if (result == 'added' && mounted) {
      widget.cubit?.loadItems();
      setState(() {
        _selectedIndex = 1; // Switch to Picked tab
      });
    }
  }

  void _handleOrderItemTap(
    BuildContext context,
    OrderItemModel item,
    String prepId,
  ) async {
    if (widget.cubit != null) {
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
      if ((result == 'updated' ||
              result == 'added' ||
              result == 'replaced' ||
              result == 'holded' ||
              result == 'canceled') &&
          mounted) {
        await widget.cubit!.reloadItemsFromApi();
        setState(() {
          if (result == 'added' ||
              result == 'replaced' ||
              result == 'canceled') {
            _selectedIndex =
                1; // Switch to Picked tab or another appropriate tab
          }
          if (result == 'holded') {
            _selectedIndex = 2; // Switch to On Hold tab
          }
        });

        // Show success message for price updates
        if (result == 'updated') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Item updated successfully! Price changes are reflected in the picked items.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
