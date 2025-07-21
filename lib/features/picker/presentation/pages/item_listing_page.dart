import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_details_model.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/category_item_list.dart';
import '../cubit/order_details_cubit.dart';
import 'order_item_details_page.dart';
import 'package:api_gateway/services/api_service.dart';
import 'package:api_gateway/http/http_client.dart';
import 'package:api_gateway/ws/websockt_client.dart';
import 'package:ansarlogisticsnew/core/routes/app_router.dart';

class ItemListingPage extends StatefulWidget {
  final List<OrderItemModel> items;
  final String? title;
  final OrderDetailsCubit? cubit;
  final String? deliveryType;
  final int? tabIndex;

  const ItemListingPage({
    Key? key,
    required this.items,
    this.title,
    this.cubit,
    this.deliveryType,
    this.tabIndex,
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
                  return OrderItemTile(
                    item: item,
                    onTap: () async {
                      if (widget.cubit != null) {
                        final result = await Navigator.pushNamed(
                          context,
                          AppRoutes.orderItemDetails,
                          arguments: {'item': item, 'cubit': widget.cubit!},
                        );
                        if (result == 'updated') {
                          setState(
                            () {},
                          ); // Refresh UI to reflect updated cubit state
                        }
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
