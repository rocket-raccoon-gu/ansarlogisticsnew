import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import 'order_item_tile.dart';
import '../pages/order_item_details_page.dart';

class ItemListWidget extends StatelessWidget {
  final List<OrderItemModel> items;
  final String emptyText;
  final int preparationId;
  const ItemListWidget({
    super.key,
    required this.items,
    required this.emptyText,
    required this.preparationId,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final cubit = BlocProvider.of<OrderDetailsCubit>(context);
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return OrderItemTile(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => OrderItemDetailsPage(
                      item: item,
                      cubit: cubit,
                      preparationId: preparationId,
                    ),
              ),
            );
          },
          onItemPicked: () {
            // Refresh the cubit when an item is picked
            if (cubit != null) {
              cubit.loadItems();
            }
          },
        );
      },
    );
  }
}
