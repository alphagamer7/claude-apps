import 'package:flutter/material.dart';
import '../models/shelf_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/item_card.dart';
import 'add_item_screen.dart';
import 'history_screen.dart';

enum FilterOption { all, expiringSoon, expired }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();
  List<ShelfItem> _items = [];
  FilterOption _filter = FilterOption.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await _db.getActiveItems();
    // Sort by days remaining (soonest first)
    items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<ShelfItem> get _filteredItems {
    switch (_filter) {
      case FilterOption.expiringSoon:
        return _items.where((i) => !i.isExpired && i.daysRemaining <= 3).toList();
      case FilterOption.expired:
        return _items.where((i) => i.isExpired).toList();
      case FilterOption.all:
        return _items;
    }
  }

  Future<void> _markAsUsed(ShelfItem item) async {
    if (item.id == null) return;
    await _db.updateItemStatus(item.id!, 'used');
    await _notif.cancelNotifications(item.id!);
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} marked as used'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markAsDiscarded(ShelfItem item) async {
    if (item.id == null) return;
    await _db.updateItemStatus(item.id!, 'discarded');
    await _notif.cancelNotifications(item.id!);
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} discarded'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShelfLife',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              _loadItems();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Filter chips
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', FilterOption.all),
                const SizedBox(width: 8),
                _buildFilterChip('Expiring Soon', FilterOption.expiringSoon),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', FilterOption.expired),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return ItemCard(
                              item: item,
                              onUsed: () => _markAsUsed(item),
                              onDiscarded: () => _markAsDiscarded(item),
                            );
                          },
                        ),
                      ),
          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (result == true) {
            _loadItems();
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterOption option) {
    final isSelected = _filter == option;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = option);
      },
      selectedColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
      checkmarkColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF2A2A2A),
      side: BorderSide(
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    switch (_filter) {
      case FilterOption.all:
        message = 'No items tracked yet.\nTap + to add your first item!';
        icon = Icons.kitchen;
      case FilterOption.expiringSoon:
        message = 'No items expiring soon.\nYou\'re in good shape!';
        icon = Icons.thumb_up;
      case FilterOption.expired:
        message = 'No expired items.\nGreat job!';
        icon = Icons.celebration;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
