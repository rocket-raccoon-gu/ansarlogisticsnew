import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_details_cubit.dart';
import '../pages/item_listing_page.dart';

class TypeCardsWidget extends StatelessWidget {
  final List<OrderItemModel> allItems;
  final OrderDetailsCubit? cubit;
  final String preparationId;
  final String? expStatus;
  final String? nolStatus;
  final String? warStatus;
  final String? supStatus;
  final String? vpoStatus;
  final String? abyStatus;
  final OrderModel order;

  const TypeCardsWidget({
    super.key,
    required this.allItems,
    this.cubit,
    required this.preparationId,
    required this.order,
    this.expStatus,
    this.nolStatus,
    this.warStatus,
    this.supStatus,
    this.vpoStatus,
    this.abyStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Get express, normal, warehouse, supplier, and vendor pickup items from the cubit state
    List<OrderItemModel> expItems = [];
    List<OrderItemModel> nolItems = [];
    List<OrderItemModel> warItems = [];
    List<OrderItemModel> supItems = [];
    List<OrderItemModel> vpoItems = [];
    List<OrderItemModel> abyItems = [];

    try {
      final state = cubit?.state;
      if (state is OrderDetailsLoaded) {
        expItems = state.expressItems;
        nolItems = state.normalItems;
        warItems = state.warehouseItems;
        supItems = state.supplierItems;
        vpoItems = state.vendorPickupItems;
        abyItems = state.abayaItems;

        // Debug logging for item retrieval
        print('🔍 TypeCardsWidget - Retrieved from cubit state:');
        print('  - Express items: ${expItems.length}');
        print('  - Normal items: ${nolItems.length}');
        print('  - Warehouse items: ${warItems.length}');
        print('  - Supplier items: ${supItems.length}');
        print('  - Vendor pickup items: ${vpoItems.length}');
        print('  - Abaya items: ${abyItems.length}');
        print(
          '  - Total items (toPick + picked + canceled + notAvailable): ${state.toPick.length + state.picked.length + state.canceled.length + state.notAvailable.length}',
        );
      }
    } catch (e) {
      print('Error getting items from cubit: $e');
      // Fallback to filtering by deliveryType if cubit is not available
      expItems = allItems.where((item) => item.deliveryType == 'exp').toList();
      nolItems = allItems.where((item) => item.deliveryType == 'nol').toList();
      warItems = allItems.where((item) => item.deliveryType == 'war').toList();
      supItems = allItems.where((item) => item.deliveryType == 'sup').toList();
      vpoItems = allItems.where((item) => item.deliveryType == 'vpo').toList();
      abyItems = allItems.where((item) => item.deliveryType == 'aby').toList();

      // Debug logging for fallback
      print('🔍 TypeCardsWidget - Using fallback filtering:');
      print('  - Express items (fallback): ${expItems.length}');
      print('  - Normal items (fallback): ${nolItems.length}');
      print('  - Warehouse items (fallback): ${warItems.length}');
      print('  - Supplier items (fallback): ${supItems.length}');
      print('  - Vendor pickup items (fallback): ${vpoItems.length}');
      print('  - Abaya items (fallback): ${abyItems.length}');
    }

    final hasEXP = expItems.isNotEmpty;
    final hasNOL = nolItems.isNotEmpty;
    final hasWAR = warItems.isNotEmpty;
    final hasSUP = supItems.isNotEmpty;
    final hasVPO = vpoItems.isNotEmpty;
    final hasABY = abyItems.isNotEmpty;

    print('TypeCardsWidget - Total items: ${allItems.length}');
    print('TypeCardsWidget - EXP items: ${expItems.length}');
    print('TypeCardsWidget - NOL items: ${nolItems.length}');
    print('TypeCardsWidget - WAR items: ${warItems.length}');
    print('TypeCardsWidget - SUP items: ${supItems.length}');
    print('TypeCardsWidget - VPO items: ${vpoItems.length}');
    print('TypeCardsWidget - ABY items: ${abyItems.length}');
    log('TypeCardsWidget - expStatus: $expStatus');
    log('TypeCardsWidget - nolStatus: $nolStatus');
    log('TypeCardsWidget - warStatus: $warStatus');
    log('TypeCardsWidget - supStatus: $supStatus');
    log('TypeCardsWidget - vpoStatus: $vpoStatus');
    log('TypeCardsWidget - abyStatus: $abyStatus');

    if (!hasEXP && !hasNOL && !hasWAR && !hasSUP && !hasVPO && !hasABY) {
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

                    if (expStatus == 'canceled_by_team') {
                      return;
                    }

                    // Debug logging before navigation
                    print(
                      '🔍 TypeCardsWidget - Navigating to EXP ItemListingPage:',
                    );
                    print('  - expItems.length: ${expItems.length}');
                    print('  - deliveryType being passed: exp');
                    print('  - expItems delivery type breakdown:');
                    for (var item in expItems) {
                      print(
                        '    - ${item.name}: deliveryType = ${item.deliveryType}',
                      );
                    }

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
                        child: Column(
                          children: [
                            Text(
                              'EXP (Express)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (expStatus != null) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(expStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  expStatus!.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

                    if (nolStatus == 'canceled_by_team') {
                      return;
                    }

                    // Debug logging before navigation
                    print(
                      '🔍 TypeCardsWidget - Navigating to NOL ItemListingPage:',
                    );
                    print('  - nolItems.length: ${nolItems.length}');
                    print('  - deliveryType being passed: nol');
                    print('  - nolItems delivery type breakdown:');
                    for (var item in nolItems) {
                      print(
                        '    - ${item.name}: deliveryType = ${item.deliveryType}',
                      );
                    }

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
                        child: Column(
                          children: [
                            Text(
                              'NOL (Normal Local)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (nolStatus != null) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(nolStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  nolStatus!.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasWAR)
            Card(
              color: Colors.purple[100],
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

                    if (warStatus == 'canceled_by_team') {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: warItems,
                              title: 'Warehouse Delivery Items',
                              cubit: orderCubit,
                              deliveryType:
                                  'war', // Pass delivery type for filtering
                              preparationId: preparationId,
                              orderNumber:
                                  warItems.isNotEmpty
                                      ? warItems.first.subgroupIdentifier ?? ''
                                      : '',
                              order: order,
                            ),
                      ),
                    );
                  } catch (e) {
                    // Handle any errors gracefully
                    print('Error navigating to Warehouse Delivery Items: $e');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Picked/Total and Progress Bar for WAR
                      Builder(
                        builder: (context) {
                          final picked =
                              warItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final total = warItems.length;
                          final progress = total > 0 ? picked / total : 0.0;

                          // Debug logging for warehouse items
                          print(
                            '🔍 WAR Progress - Total: $total, Picked: $picked, Progress: ${(progress * 100).toStringAsFixed(1)}%',
                          );
                          print('🔍 WAR Items Status Breakdown:');
                          for (var item in warItems) {
                            print('  - ${item.name}: ${item.status}');
                          }

                          // Additional status count verification
                          final toPickCount =
                              warItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.toPick,
                                  )
                                  .length;
                          final pickedCount =
                              warItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final holdedCount =
                              warItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.holded,
                                  )
                                  .length;
                          final notAvailableCount =
                              warItems
                                  .where(
                                    (item) =>
                                        item.status ==
                                        OrderItemStatus.itemNotAvailable,
                                  )
                                  .length;
                          final canceledCount =
                              warItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.canceled,
                                  )
                                  .length;

                          print(
                            '🔍 WAR Status Counts - ToPick: $toPickCount, Picked: $pickedCount, Holded: $holdedCount, NotAvailable: $notAvailableCount, Canceled: $canceledCount',
                          );
                          print(
                            '🔍 WAR Verification - Total should be: ${toPickCount + pickedCount + holdedCount + notAvailableCount + canceledCount}',
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
                                      backgroundColor: Colors.purple[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.purple[900]!,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '$picked/$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.purple[900],
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
                        child: Column(
                          children: [
                            Text(
                              'WAR (Warehouse)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (warStatus != null) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(warStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  warStatus!.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasSUP)
            Card(
              color: Colors.teal[100],
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

                    if (supStatus == 'canceled_by_team') {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: supItems,
                              title: 'Supplier Delivery Items',
                              cubit: orderCubit,
                              deliveryType:
                                  'sup', // Pass delivery type for filtering
                              preparationId: preparationId,
                              orderNumber:
                                  supItems.isNotEmpty
                                      ? supItems.first.subgroupIdentifier ?? ''
                                      : '',
                              order: order,
                            ),
                      ),
                    );
                  } catch (e) {
                    // Handle any errors gracefully
                    print('Error navigating to Supplier Delivery Items: $e');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Picked/Total and Progress Bar for SUP
                      Builder(
                        builder: (context) {
                          final picked =
                              supItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final total = supItems.length;
                          final progress = total > 0 ? picked / total : 0.0;

                          // Debug logging for supplier items
                          print(
                            '🔍 SUP Progress - Total: $total, Picked: $picked, Progress: ${(progress * 100).toStringAsFixed(1)}%',
                          );
                          print('🔍 SUP Items Status Breakdown:');
                          for (var item in supItems) {
                            print('  - ${item.name}: ${item.status}');
                          }

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
                                      backgroundColor: Colors.teal[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.teal[900]!,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '$picked/$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.teal[900],
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
                        child: Column(
                          children: [
                            Text(
                              'SUP (Supplier)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (supStatus != null) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(supStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  supStatus!.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasVPO)
            Card(
              color: Colors.indigo[100],
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

                    if (vpoStatus == 'canceled_by_team') {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: vpoItems,
                              title: 'Vendor Pickup Items',
                              cubit: orderCubit,
                              deliveryType:
                                  'vpo', // Pass delivery type for filtering
                              preparationId: preparationId,
                              orderNumber:
                                  vpoItems.isNotEmpty
                                      ? vpoItems.first.subgroupIdentifier ?? ''
                                      : '',
                              order: order,
                            ),
                      ),
                    );
                  } catch (e) {
                    // Handle any errors gracefully
                    print('Error navigating to Vendor Pickup Items: $e');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Picked/Total and Progress Bar for VPO
                      Builder(
                        builder: (context) {
                          final picked =
                              vpoItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final total = vpoItems.length;
                          final progress = total > 0 ? picked / total : 0.0;

                          // Debug logging for vendor pickup items
                          print(
                            '🔍 VPO Progress - Total: $total, Picked: $picked, Progress: ${(progress * 100).toStringAsFixed(1)}%',
                          );
                          print('🔍 VPO Items Status Breakdown:');
                          for (var item in vpoItems) {
                            print('  - ${item.name}: ${item.status}');
                          }

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
                                      backgroundColor: Colors.indigo[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.indigo[900]!,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '$picked/$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.indigo[900],
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
                        child: Column(
                          children: [
                            Text(
                              'VPO (Vendor Pickup)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (vpoStatus != null) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(vpoStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  vpoStatus!.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (hasABY)
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

                    if (abyStatus == 'canceled_by_team') {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemListingPage(
                              items: abyItems,
                              title: 'Abaya Orders',
                              cubit: orderCubit,
                              deliveryType:
                                  'aby', // Pass delivery type for filtering
                              preparationId: preparationId,
                              orderNumber:
                                  abyItems.isNotEmpty
                                      ? abyItems.first.subgroupIdentifier ?? ''
                                      : '',
                              order: order,
                            ),
                      ),
                    );
                  } catch (e) {
                    // Handle any errors gracefully
                    print('Error navigating to Abaya Orders: $e');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Picked/Total and Progress Bar for ABY
                      Builder(
                        builder: (context) {
                          final picked =
                              abyItems
                                  .where(
                                    (item) =>
                                        item.status == OrderItemStatus.picked,
                                  )
                                  .length;
                          final total = abyItems.length;
                          final progress = total > 0 ? picked / total : 0.0;

                          // Debug logging for abaya items
                          print(
                            '🔍 ABY Progress - Total: $total, Picked: $picked, Progress: ${(progress * 100).toStringAsFixed(1)}%',
                          );
                          print('🔍 ABY Items Status Breakdown:');
                          for (var item in abyItems) {
                            print('  - ${item.name}: ${item.status}');
                          }

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
                                        Colors.orange[900]!,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '$picked/$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.orange[900],
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
                        child: Column(
                          children: [
                            Text(
                              'ABY (Abaya Orders)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (abyStatus != null) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(abyStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  abyStatus!.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'start_picking':
        return Colors.blue;
      case 'end_picking':
        return Colors.green;
      case 'canceled_by_team':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
