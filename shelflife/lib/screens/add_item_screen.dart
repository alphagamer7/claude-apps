import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/shelf_life_guide.dart';
import '../models/shelf_item.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/category_chip.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _daysController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();

  String? _selectedCategory;
  DateTime _openedDate = DateTime.now();
  String? _selectedSuggestion;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _selectedCategory != null &&
      _daysController.text.isNotEmpty &&
      int.tryParse(_daysController.text) != null &&
      int.parse(_daysController.text) > 0;

  Future<void> _save() async {
    if (!_isValid || _saving) return;

    setState(() => _saving = true);

    final item = ShelfItem(
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      openedDate: _openedDate,
      shelfLifeDays: int.parse(_daysController.text),
    );

    final id = await _db.insertItem(item);
    final savedItem = item.copyWith(id: id);

    await _notif.scheduleExpiryNotifications(savedItem);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _openedDate = picked);
    }
  }

  void _selectSuggestion(String name, int days) {
    setState(() {
      _selectedSuggestion = name;
      _nameController.text = name;
      _daysController.text = days.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _selectedCategory != null
        ? ShelfLifeGuide.getItemsForCategory(_selectedCategory!)
        : <String, int>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category picker
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ShelfLifeGuide.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = ShelfLifeGuide.categories[index];
                  return CategoryChip(
                    category: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _selectedSuggestion = null;
                        _nameController.clear();
                        _daysController.clear();
                      });
                    },
                  );
                },
              ),
            ),

            // Suggestions
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.entries.map((entry) {
                  final isSelected = _selectedSuggestion == entry.key;
                  return ActionChip(
                    label: Text('${entry.key} (${entry.value}d)'),
                    onPressed: () => _selectSuggestion(entry.key, entry.value),
                    backgroundColor: isSelected
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : const Color(0xFF2A2A2A),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade300,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade700,
                    ),
                  );
                }).toList(),
              ),
            ],

            // Name field
            const SizedBox(height: 24),
            const Text(
              'Item Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Milk, Yogurt...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
              onChanged: (_) => setState(() => _selectedSuggestion = null),
            ),

            // Shelf life days
            const SizedBox(height: 24),
            const Text(
              'Shelf Life (days after opening)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Number of days',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                ),
                suffixText: 'days',
                suffixStyle: TextStyle(color: Colors.grey.shade400),
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Opened date
            const SizedBox(height: 24),
            const Text(
              'Opened Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMM d, y').format(_openedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.edit, color: Colors.grey.shade500, size: 18),
                  ],
                ),
              ),
            ),

            // Save button
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isValid ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
