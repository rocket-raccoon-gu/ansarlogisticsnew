import 'package:flutter/material.dart';
import '../../data/models/order_details_model.dart';
import '../../data/models/order_model.dart';
import '../widgets/order_item_tile.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/order_item_details_page.dart';
import 'package:ansarlogisticsnew/core/constants/app_colors.dart';

class CategoryItemList extends StatefulWidget {
  final List<CategoryItemModel> categories;
  final OrderDetailsCubit? cubit;
  final int preparationId;
  final OrderModel order;

  const CategoryItemList({
    Key? key,
    required this.categories,
    this.cubit,
    required this.preparationId,
    required this.order,
  }) : super(key: key);

  @override
  State<CategoryItemList> createState() => _CategoryItemListState();
}

class _CategoryItemListState extends State<CategoryItemList> {
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Initially expand all categories
    for (var category in widget.categories) {
      _expandedCategories[category.category] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(
        child: Text(
          'No items available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.categories.length,
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final isExpanded = _expandedCategories[category.category] ?? true;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Category Header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCategories[category.category] = !isExpanded;
                  });
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${category.items.length} item${category.items.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Category Items
              if (isExpanded)
                Column(
                  children:
                      category.items.map((item) {
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
                                        preparationId: widget.preparationId,
                                        order: widget.order,
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
                      }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
