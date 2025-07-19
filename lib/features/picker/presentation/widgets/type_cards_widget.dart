import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/item_listing_page.dart';

class TypeCardsWidget extends StatelessWidget {
  final List<OrderItemModel> allItems;

  const TypeCardsWidget({super.key, required this.allItems});

  @override
  Widget build(BuildContext context) {
    final expItems =
        allItems.where((item) => item.deliveryType == 'exp').toList();
    final nolItems =
        allItems.where((item) => item.deliveryType == 'nol').toList();
    final hasEXP = expItems.isNotEmpty;
    final hasNOL = nolItems.isNotEmpty;

    if (!hasEXP && !hasNOL) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (hasEXP)
            Card(
              color: Colors.orange[100],
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ItemListingPage(
                            items: expItems,
                            title: 'Express Items',
                            cubit: BlocProvider.of<OrderDetailsCubit>(context),
                          ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'EXP (Express)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          if (hasNOL)
            Card(
              color: Colors.blue[100],
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ItemListingPage(
                            items: nolItems,
                            title: 'Normal Local Items',
                            cubit: BlocProvider.of<OrderDetailsCubit>(context),
                          ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'NOL (Normal Local)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
