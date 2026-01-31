import 'package:flutter/material.dart';
import '../models/pack_item.dart';
import '../models/template.dart';
import '../services/database_service.dart';
import '../widgets/category_section.dart';

class TemplateEditorScreen extends StatefulWidget {
  final int? templateId;

  const TemplateEditorScreen({super.key, this.templateId});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _db = DatabaseService();
  final _nameController = TextEditingController();
  List<PackItem> _items = [];
  bool _loading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.templateId != null;
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    if (_isEditing) {
      final template = await _db.getTemplate(widget.templateId!);
      if (template != null) {
        _nameController.text = template.name;
        _items = List.from(template.items);
      }
    }
    setState(() => _loading = false);
  }

  Map<String, List<PackItem>> get _itemsByCategory {
    final map = <String, List<PackItem>>{};
    for (final category in PackItem.categories) {
      final items = _items.where((i) => i.category == category).toList();
      map[category] = items;
    }
    return map;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Template' : 'New Template',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saveTemplate,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF00BCD4),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final categories = _itemsByCategory;

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Name input
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: 'Template name',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white12),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00BCD4)),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Add items to each category. Swipe to remove.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        // Category sections
        for (final category in PackItem.categories)
          CategorySection(
            category: category,
            items: categories[category] ?? [],
            showCheckboxes: false,
            onItemDismissed: (item) {
              setState(() {
                _items.removeWhere((i) =>
                    i.name == item.name && i.category == item.category);
              });
            },
            onAddItem: () => _addItemToCategory(category),
          ),
      ],
    );
  }

  void _addItemToCategory(String category) async {
    final name = await _showAddItemDialog();
    if (name == null || name.isEmpty) return;

    setState(() {
      final maxSort = _items.isEmpty
          ? 0
          : _items.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b);
      _items.add(PackItem(
        name: name,
        category: category,
        sortOrder: maxSort + 1,
      ));
    });
  }

  void _saveTemplate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    if (_isEditing) {
      final template = Template(
        id: widget.templateId,
        name: name,
        items: _items,
      );
      await _db.updateTemplate(template);
    } else {
      final template = Template(
        name: name,
        items: _items,
      );
      await _db.insertTemplate(template);
    }

    if (mounted) {
      Navigator.pop(context);
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
