import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/item_listing_page.dart';

class TypeCardsWidget extends StatelessWidget {
  final List<OrderItemModel> allItems;
  final OrderDetailsCubit? cubit;
  final int preparationId;
  final OrderModel order;

  const TypeCardsWidget({
    super.key,
    required this.allItems,
    this.cubit,
    required this.preparationId,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    // Get express and normal items from the cubit state
    List<OrderItemModel> expItems = [];
    List<OrderItemModel> nolItems = [];

    try {
      final state = cubit?.state;
      if (state is OrderDetailsLoaded) {
        expItems = state.expressItems;
        nolItems = state.normalItems;

        // Debug logging for item retrieval
        print('🔍 TypeCardsWidget - Retrieved from cubit state:');
        print('  - Express items: ${expItems.length}');
        print('  - Normal items: ${nolItems.length}');
        print(
          '  - Total items (toPick + picked + canceled + notAvailable): ${state.toPick.length + state.picked.length + state.canceled.length + state.notAvailable.length}',
        );
      }
    } catch (e) {
      print('Error getting express/normal items from cubit: $e');
      // Fallback to filtering by deliveryType if cubit is not available
      expItems = allItems.where((item) => item.deliveryType == 'exp').toList();
      nolItems = allItems.where((item) => item.deliveryType == 'nol').toList();

      // Debug logging for fallback
      print('🔍 TypeCardsWidget - Using fallback filtering:');
      print('  - Express items (fallback): ${expItems.length}');
      print('  - Normal items (fallback): ${nolItems.length}');
    }

    final hasEXP = expItems.isNotEmpty;
    final hasNOL = nolItems.isNotEmpty;

    print('TypeCardsWidget - Total items: ${allItems.length}');
    print('TypeCardsWidget - EXP items: ${expItems.length}');
    print('TypeCardsWidget - NOL items: ${nolItems.length}');

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
                  try {
                    // Check if context is still valid
                    if (!context.mounted) return;

                    // Use the passed cubit or try to get it from context safely
                    OrderDetailsCubit? orderCubit = cubit;
                    if (orderCubit == null && context.mounted) {
                      try {
                        orderCubit = BlocProvider.of<OrderDetailsCubit>(
                          context,
                        );
                      } catch (e) {
                        print('Could not get cubit from context: $e');
                        return;
                      }
                    }

                    // Double check if context is still valid
                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: expItems,
                              title: 'Express Items',
                              cubit: orderCubit,
                              deliveryType:
                                  'exp', // Pass delivery type for filtering
                              preparationId: preparationId,
                              orderNumber:
                                  expItems.isNotEmpty
                                      ? expItems.first.subgroupIdentifier ?? ''
                                      : '',
                              order: order,
                            ),
                      ),
                    );
                  } catch (e) {
                    // Handle any errors gracefully
                    print('Error navigating to Express Items: $e');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Picked/Total and Progress Bar for Express
                      Builder(
                        builder: (context) {
                          final picked =
                              expItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final total = expItems.length;
                          final progress = total > 0 ? picked / total : 0.0;

                          // Debug logging for express items
                          print(
                            '🔍 EXP Progress - Total: $total, Picked: $picked, Progress: ${(progress * 100).toStringAsFixed(1)}%',
                          );
                          print('🔍 EXP Items Status Breakdown:');
                          for (var item in expItems) {
                            print('  - ${item.name}: ${item.status}');
                          }

                          // Additional status count verification
                          final toPickCount =
                              expItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.toPick,
                                  )
                                  .length;
                          final pickedCount =
                              expItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final holdedCount =
                              expItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.holded,
                                  )
                                  .length;
                          final notAvailableCount =
                              expItems
                                  .where(
                                    (item) =>
                                        item.status ==
                                        OrderItemStatus.itemNotAvailable,
                                  )
                                  .length;
                          final canceledCount =
                              expItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.canceled,
                                  )
                                  .length;

                          print(
                            '🔍 EXP Status Counts - ToPick: $toPickCount, Picked: $pickedCount, Holded: $holdedCount, NotAvailable: $notAvailableCount, Canceled: $canceledCount',
                          );
                          print(
                            '🔍 EXP Verification - Total should be: ${toPickCount + pickedCount + holdedCount + notAvailableCount + canceledCount}',
                          );

                          return Column(
                            children: [
                              SizedBox(
                                height: 56,
                                width: 56,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.orange[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.deepOrange,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '$picked/$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      Center(
                        child: Text(
                          'EXP (Express)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasNOL)
            Card(
              color: Colors.blue[100],
              child: InkWell(
                onTap: () {
                  try {
                    // Check if context is still valid
                    if (!context.mounted) return;

                    // Use the passed cubit or try to get it from context safely
                    OrderDetailsCubit? orderCubit = cubit;
                    if (orderCubit == null && context.mounted) {
                      try {
                        orderCubit = BlocProvider.of<OrderDetailsCubit>(
                          context,
                        );
                      } catch (e) {
                        print('Could not get cubit from context: $e');
                        return;
                      }
                    }

                    // Double check if context is still valid
                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: nolItems,
                              title: 'Normal Local Items',
                              cubit: orderCubit,
                              deliveryType:
                                  'nol', // Pass delivery type for filtering
                              preparationId: preparationId,
                              orderNumber:
                                  nolItems.isNotEmpty
                                      ? nolItems.first.subgroupIdentifier ?? ''
                                      : '',
                              order: order,
                            ),
                      ),
                    );
                  } catch (e) {
                    // Handle any errors gracefully
                    print('Error navigating to Normal Local Items: $e');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Picked/Total and Progress Bar for NOL
                      Builder(
                        builder: (context) {
                          final picked =
                              nolItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final total = nolItems.length;
                          final progress = total > 0 ? picked / total : 0.0;

                          // Debug logging for normal items
                          print(
                            '🔍 NOL Progress - Total: $total, Picked: $picked, Progress: ${(progress * 100).toStringAsFixed(1)}%',
                          );
                          print('🔍 NOL Items Status Breakdown:');
                          for (var item in nolItems) {
                            print('  - ${item.name}: ${item.status}');
                          }

                          // Additional status count verification
                          final toPickCount =
                              nolItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.toPick,
                                  )
                                  .length;
                          final pickedCount =
                              nolItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final holdedCount =
                              nolItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.holded,
                                  )
                                  .length;
                          final notAvailableCount =
                              nolItems
                                  .where(
                                    (item) =>
                                        item.status ==
                                        OrderItemStatus.itemNotAvailable,
                                  )
                                  .length;
                          final canceledCount =
                              nolItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.canceled,
                                  )
                                  .length;

                          print(
                            '🔍 NOL Status Counts - ToPick: $toPickCount, Picked: $pickedCount, Holded: $holdedCount, NotAvailable: $notAvailableCount, Canceled: $canceledCount',
                          );
                          print(
                            '🔍 NOL Verification - Total should be: ${toPickCount + pickedCount + holdedCount + notAvailableCount + canceledCount}',
                          );

                          return Column(
                            children: [
                              SizedBox(
                                height: 56,
                                width: 56,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.blue[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue[900]!,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '$picked/$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      Center(
                        child: Text(
                          'NOL (Normal Local)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
