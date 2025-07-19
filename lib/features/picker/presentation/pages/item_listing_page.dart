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

  const ItemListingPage({Key? key, required this.items, this.title, this.cubit})
    : super(key: key);

  @override
  State<ItemListingPage> createState() => _ItemListingPageState();
}

class _ItemListingPageState extends State<ItemListingPage> {
  int _selectedIndex = 0;

  List<OrderItemModel> _getFilteredItems(List<OrderItemModel> allItems) {
    switch (_selectedIndex) {
      case 0:
        return allItems
            .where((item) => item.status == OrderItemStatus.toPick)
            .toList();
      case 1:
        return allItems
            .where((item) => item.status == OrderItemStatus.picked)
            .toList();
      case 2:
        return allItems
            .where((item) => item.status == OrderItemStatus.canceled)
            .toList();
      case 3:
        return allItems
            .where((item) => item.status == OrderItemStatus.notAvailable)
            .toList();
      default:
        return allItems;
    }
  }

  List<CategoryItemModel> _getFilteredCategories(
    List<CategoryItemModel> allCategories,
  ) {
    switch (_selectedIndex) {
      case 0:
        return allCategories
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
        return allCategories
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
        return allCategories
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
        return allCategories
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
        return allCategories;
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
            final filteredCategories = _getFilteredCategories(state.categories);

            return _buildScaffold(filteredCategories);
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
      // Fallback to original behavior if no cubit provided
      final filteredItems = _getFilteredItems(widget.items);
      return _buildScaffoldWithItems(filteredItems);
    }
  }

  Widget _buildScaffold(List<CategoryItemModel> filteredCategories) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Items')),
      body:
          filteredCategories.isEmpty
              ? Center(child: Text(_emptyText))
              : CategoryItemList(
                categories: filteredCategories,
                cubit: widget.cubit,
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
                  return OrderItemTile(
                    item: item,
                    onTap: () {
                      if (widget.cubit != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => OrderItemDetailsPage(
                                  item: item,
                                  cubit: widget.cubit!,
                                ),
                          ),
                        );
                      }
                    },
                    onItemPicked: () {
                      // Refresh the cubit when an item is picked
                      if (widget.cubit != null) {
                        widget.cubit!.loadItems();
                      }
                    },
                  );
                },
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
}
