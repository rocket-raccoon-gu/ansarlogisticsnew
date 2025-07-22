import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_details_model.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/category_item_list.dart';
import '../cubit/order_details_cubit.dart';
import 'order_item_details_page.dart';

class ItemListingPage extends StatefulWidget {
  final List<OrderItemModel> items;
  final String? title;
  final OrderDetailsCubit? cubit;
  final String? deliveryType;
  final int? tabIndex;
  final int preparationId;

  const ItemListingPage({
    Key? key,
    required this.items,
    this.title,
    this.cubit,
    this.deliveryType,
    this.tabIndex,
    required this.preparationId,
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
            .where((item) => item.status == OrderItemStatus.canceled)
            .toList();
      case 3:
        return filtered
            .where((item) => item.status == OrderItemStatus.notAvailable)
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
                        .where(
                          (item) => item.status == OrderItemStatus.canceled,
                        )
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
                          (item) => item.status == OrderItemStatus.notAvailable,
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
        return 'No canceled items';
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
              appBar: AppBar(title: Text(widget.title ?? 'Items')),
              body:
                  tabFilteredCategories.isEmpty
                      ? Center(child: Text(_emptyText))
                      : CategoryItemList(
                        categories: tabFilteredCategories,
                        cubit: widget.cubit,
                        preparationId: widget.preparationId,
                      ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showAddItemSheet(widget.cubit!),
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
                    icon: Icon(Icons.cancel_outlined),
                    label: 'Canceled',
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
        onPressed: () => _showAddItemSheet(widget.cubit!),
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
            icon: Icon(Icons.cancel_outlined),
            label: 'Canceled',
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

  void _showAddItemSheet(OrderDetailsCubit cubit) {
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    //   ),
    //   builder: (context) {
    //     final _formKey = GlobalKey<FormState>();
    //     String name = '';
    //     String sku = '';
    //     String price = '';
    //     String quantity = '';
    //     return Padding(
    //       padding: EdgeInsets.only(
    //         left: 20,
    //         right: 20,
    //         top: 24,
    //         bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    //       ),
    //       child: Form(
    //         key: _formKey,
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Center(
    //               child: Container(
    //                 width: 40,
    //                 height: 4,
    //                 margin: const EdgeInsets.only(bottom: 16),
    //                 decoration: BoxDecoration(
    //                   color: Colors.grey[300],
    //                   borderRadius: BorderRadius.circular(2),
    //                 ),
    //               ),
    //             ),
    //             const Text(
    //               'Add New Item',
    //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    //             ),
    //             const SizedBox(height: 18),
    //             TextFormField(
    //               decoration: const InputDecoration(
    //                 labelText: 'Name',
    //                 border: OutlineInputBorder(),
    //               ),
    //               validator:
    //                   (v) =>
    //                       v == null || v.trim().isEmpty ? 'Enter name' : null,
    //               onChanged: (v) => name = v,
    //             ),
    //             const SizedBox(height: 12),
    //             TextFormField(
    //               decoration: const InputDecoration(
    //                 labelText: 'SKU',
    //                 border: OutlineInputBorder(),
    //               ),
    //               validator:
    //                   (v) => v == null || v.trim().isEmpty ? 'Enter SKU' : null,
    //               onChanged: (v) => sku = v,
    //             ),
    //             const SizedBox(height: 12),
    //             TextFormField(
    //               decoration: const InputDecoration(
    //                 labelText: 'Price',
    //                 border: OutlineInputBorder(),
    //               ),
    //               keyboardType: TextInputType.numberWithOptions(decimal: true),
    //               validator:
    //                   (v) =>
    //                       v == null || v.trim().isEmpty ? 'Enter price' : null,
    //               onChanged: (v) => price = v,
    //             ),
    //             const SizedBox(height: 12),
    //             TextFormField(
    //               decoration: const InputDecoration(
    //                 labelText: 'Quantity',
    //                 border: OutlineInputBorder(),
    //               ),
    //               keyboardType: TextInputType.number,
    //               validator:
    //                   (v) =>
    //                       v == null || v.trim().isEmpty
    //                           ? 'Enter quantity'
    //                           : null,
    //               onChanged: (v) => quantity = v,
    //             ),
    //             const SizedBox(height: 20),
    //             SizedBox(
    //               width: double.infinity,
    //               child: ElevatedButton(
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: Colors.blue,
    //                   foregroundColor: Colors.white,
    //                   padding: const EdgeInsets.symmetric(vertical: 14),
    //                   textStyle: const TextStyle(
    //                     fontSize: 16,
    //                     fontWeight: FontWeight.bold,
    //                   ),
    //                 ),
    //                 onPressed: () {
    //                   if (_formKey.currentState!.validate()) {
    //                     // TODO: Add logic to actually add the item to the list or backend
    //                     Navigator.pop(context);
    //                     ScaffoldMessenger.of(context).showSnackBar(
    //                       const SnackBar(
    //                         content: Text('Item added (demo only).'),
    //                       ),
    //                     );
    //                   }
    //                 },
    //                 child: const Text('Add Item'),
    //               ),
    //             ),
    //           ],
    //         ),
    //       );
    //     },
    //   ),

    // );
    Navigator.pushNamed(
      context,
      '/item_add_page',
      arguments: {'preparationId': widget.preparationId, 'cubit': widget.cubit},
    );
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
            ),
      ),
    );
    if (result == 'updated' || result == 'added') {
      widget.cubit!.loadItems();
      setState(() {
        if (result == 'added') {
          _selectedIndex = 1; // Switch to Picked tab
        }
      });
    }
  }
}
