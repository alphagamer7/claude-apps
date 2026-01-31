import 'package:flutter/material.dart';
import '../models/pack_item.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import '../widgets/category_section.dart';
import '../widgets/progress_bar.dart';

class ChecklistScreen extends StatefulWidget {
  final int tripId;

  const ChecklistScreen({super.key, required this.tripId});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _db = DatabaseService();
  Trip? _trip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final trip = await _db.getTrip(widget.tripId);
    setState(() {
      _trip = trip;
      _loading = false;
    });
  }

  Map<String, List<PackItem>> get _itemsByCategory {
    if (_trip == null) return {};
    final map = <String, List<PackItem>>{};
    for (final category in PackItem.categories) {
      final items =
          _trip!.items.where((i) => i.category == category).toList();
      if (items.isNotEmpty) {
        map[category] = items;
      }
    }
    // Add any items with unknown categories
    final knownCategories = PackItem.categories.toSet();
    for (final item in _trip!.items) {
      if (!knownCategories.contains(item.category)) {
        map.putIfAbsent(item.category, () => []).add(item);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _trip?.name ?? 'Loading...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF2A2A2A),
            onSelected: _handleAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset All',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trip == null
              ? const Center(
                  child: Text('Trip not found',
                      style: TextStyle(color: Colors.white38)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final categories = _itemsByCategory;

    return Column(
      children: [
        // Progress bar at top
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white.withValues(alpha: 0.03),
          child: PackingProgressBar(
            checked: _trip!.checkedCount,
            total: _trip!.totalCount,
            height: 10,
          ),
        ),
        // Checklist
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              for (final category in PackItem.categories)
                if (categories.containsKey(category))
                  CategorySection(
                    category: category,
                    items: categories[category]!,
                    showCheckboxes: true,
                    onItemToggled: _toggleItem,
                    onItemDismissed: _deleteItem,
                    onAddItem: () => _addItemToCategory(category),
                  ),
              // Unknown categories
              for (final entry in categories.entries)
                if (!PackItem.categories.contains(entry.key))
                  CategorySection(
                    category: entry.key,
                    items: entry.value,
                    showCheckboxes: true,
                    onItemToggled: _toggleItem,
                    onItemDismissed: _deleteItem,
                    onAddItem: () => _addItemToCategory(entry.key),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleItem(PackItem item) async {
    if (item.id == null) return;
    await _db.toggleTripItem(item.id!, !item.isChecked);
    await _loadTrip();
  }

  void _deleteItem(PackItem item) async {
    if (item.id == null) return;
    await _db.deleteTripItem(item.id!);
    await _loadTrip();
  }

  void _addItemToCategory(String category) async {
    final name = await _showAddItemDialog();
    if (name == null || name.isEmpty) return;

    final maxSort = _trip!.items.isEmpty
        ? 0
        : _trip!.items
            .map((i) => i.sortOrder)
            .reduce((a, b) => a > b ? a : b);

    final item = PackItem(
      name: name,
      category: category,
      sortOrder: maxSort + 1,
    );
    await _db.addTripItem(widget.tripId, item);
    await _loadTrip();
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'reset':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('Reset All Items?',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'This will uncheck all items so you can reuse this list.',
              style: TextStyle(color: Colors.white54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset',
                    style: TextStyle(color: Color(0xFF00BCD4))),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _db.resetTripItems(widget.tripId);
          await _loadTrip();
        }
        break;
    }
  }

  Future<String?> _showAddItemDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title:
            const Text('Add Item', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Item name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00BCD4)),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add',
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }
}
