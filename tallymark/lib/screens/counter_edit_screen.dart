import 'package:flutter/material.dart';
import '../models/counter.dart';
import '../services/database_service.dart';

class CounterEditScreen extends StatefulWidget {
  final Counter? counter;

  const CounterEditScreen({super.key, this.counter});

  @override
  State<CounterEditScreen> createState() => _CounterEditScreenState();
}

class _CounterEditScreenState extends State<CounterEditScreen> {
  final DatabaseService _db = DatabaseService();
  final _nameController = TextEditingController();
  int _selectedColor = 0xFFFF9800; // Orange default
  bool _dailyReset = false;

  bool get _isEditing => widget.counter != null;

  static const List<int> _presetColors = [
    0xFFFF9800, // Orange
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFF8BC34A, // Light Green
    0xFFCDDC39, // Lime
    0xFFFFEB3B, // Yellow
    0xFFFF5722, // Deep Orange
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFFF44336, // Red
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.counter!.name;
      _selectedColor = widget.counter!.color;
      _dailyReset = widget.counter!.dailyReset;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    if (_isEditing) {
      final updated = widget.counter!.copyWith(
        name: name,
        color: _selectedColor,
        dailyReset: _dailyReset,
      );
      await _db.updateCounter(updated);
    } else {
      final counter = Counter(
        name: name,
        color: _selectedColor,
        dailyReset: _dailyReset,
      );
      await _db.insertCounter(counter);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!_isEditing || widget.counter!.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Counter'),
        content:
            Text('Delete "${widget.counter!.name}" and all its history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteCounter(widget.counter!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Counter' : 'New Counter'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Name input
          TextField(
            controller: _nameController,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Counter Name',
              hintText: 'e.g. Push-ups, Coffees, Ideas...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(_selectedColor),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Color picker
          Text(
            'Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presetColors.map((colorValue) {
              final isSelected = colorValue == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(colorValue).withAlpha(isSelected ? 255 : 150),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(colorValue).withAlpha(100),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Daily reset toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Reset Daily'),
              subtitle: Text(
                'Counter resets to 0 each day',
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 13,
                ),
              ),
              value: _dailyReset,
              onChanged: (val) => setState(() => _dailyReset = val),
              activeTrackColor: Color(_selectedColor).withAlpha(80),
            ),
          ),

          // Delete option
          if (_isEditing) ...[
            const SizedBox(height: 48),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Counter',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
