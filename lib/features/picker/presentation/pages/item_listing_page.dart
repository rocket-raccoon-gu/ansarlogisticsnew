import 'package:flutter/material.dart';
import '../../data/models/order_item_model.dart';

class ItemListingPage extends StatefulWidget {
  final List<OrderItemModel> items;
  final String? title;
  const ItemListingPage({Key? key, required this.items, this.title})
    : super(key: key);

  @override
  State<ItemListingPage> createState() => _ItemListingPageState();
}

class _ItemListingPageState extends State<ItemListingPage> {
  int _selectedIndex = 0;

  List<OrderItemModel> get _filteredItems {
    switch (_selectedIndex) {
      case 0:
        return widget.items
            .where((item) => item.status == OrderItemStatus.toPick)
            .toList();
      case 1:
        return widget.items
            .where((item) => item.status == OrderItemStatus.picked)
            .toList();
      case 2:
        return widget.items
            .where((item) => item.status == OrderItemStatus.canceled)
            .toList();
      case 3:
        return widget.items
            .where((item) => item.status == OrderItemStatus.notAvailable)
            .toList();
      default:
        return widget.items;
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Items')),
      body:
          _filteredItems.isEmpty
              ? Center(child: Text(_emptyText))
              : ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(item.status.toString().split('.').last),
                    // Add onTap or more details as needed
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
