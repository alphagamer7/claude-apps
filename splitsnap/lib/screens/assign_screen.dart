import 'package:flutter/material.dart';
import '../models/split_item.dart';
import '../models/split_session.dart';
import '../widgets/item_tile.dart';
import '../widgets/person_chip.dart';
import 'summary_screen.dart';

class AssignScreen extends StatefulWidget {
  final List<SplitItem> items;

  const AssignScreen({super.key, required this.items});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  late List<SplitItem> _items;
  final List<String> _people = [];
  String? _selectedPerson;
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0.00');
  final TextEditingController _tipController = TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void dispose() {
    _personController.dispose();
    _taxController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _personController.text.trim();
    if (name.isEmpty) return;
    if (_people.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Person already added')),
      );
      return;
    }
    setState(() {
      _people.add(name);
      _selectedPerson = name;
      _personController.clear();
    });
  }

  void _removePerson(String name) {
    setState(() {
      _people.remove(name);
      // Unassign items from removed person
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].assignedPerson == name) {
          _items[i] = _items[i].copyWith(clearPerson: true);
        }
      }
      if (_selectedPerson == name) {
        _selectedPerson = _people.isNotEmpty ? _people.first : null;
      }
    });
  }

  void _onItemTap(int index) {
    if (_people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add people first before assigning items'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      final item = _items[index];
      if (item.assignedPerson == null) {
        // Assign to selected person
        _items[index] = item.copyWith(
          assignedPerson: _selectedPerson ?? _people.first,
        );
      } else {
        // Cycle through people
        final currentIndex = _people.indexOf(item.assignedPerson!);
        if (currentIndex == _people.length - 1) {
          // After last person, unassign
          _items[index] = item.copyWith(clearPerson: true);
        } else {
          // Move to next person
          _items[index] = item.copyWith(
            assignedPerson: _people[currentIndex + 1],
          );
        }
      }
    });
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Item', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Item name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              if (name.isNotEmpty && price != null && price > 0) {
                setState(() {
                  _items.add(SplitItem(name: name, price: price));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(int index) {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Item', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Item name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              if (name.isNotEmpty && price != null && price > 0) {
                setState(() {
                  _items[index] = item.copyWith(name: name, price: price);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _goToSummary() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }
    if (_people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one person')),
      );
      return;
    }

    final tax = double.tryParse(_taxController.text) ?? 0.0;
    final tip = double.tryParse(_tipController.text) ?? 0.0;

    final session = SplitSession(
      items: _items,
      people: _people,
      taxAmount: tax,
      tipAmount: tip,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryScreen(session: session),
      ),
    );
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Items'),
        actions: [
          TextButton(
            onPressed: _goToSummary,
            child: const Text(
              'Summary',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // People section
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'People',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _personController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a name...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addPerson(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addPerson,
                      icon: const Icon(Icons.person_add,
                          color: Color(0xFF4CAF50)),
                    ),
                  ],
                ),
                if (_people.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _people.map((name) {
                      return PersonChip(
                        name: name,
                        isSelected: _selectedPerson == name,
                        onTap: () {
                          setState(() => _selectedPerson = name);
                        },
                        onDelete: () => _removePerson(name),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Items header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_items.length} items',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Subtotal: \$${_subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      'No items yet.\nTap + to add manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return ItemTile(
                        item: _items[index],
                        onTap: () => _onItemTap(index),
                        onEdit: () => _showEditItemDialog(index),
                        onDelete: () => _deleteItem(index),
                      );
                    },
                  ),
          ),
          // Tax and Tip
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tax',
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: Colors.white),
                      labelStyle: const TextStyle(color: Colors.grey),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _tipController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tip',
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: Colors.white),
                      labelStyle: const TextStyle(color: Colors.grey),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
