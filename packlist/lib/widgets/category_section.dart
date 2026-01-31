import 'package:flutter/material.dart';
import '../models/pack_item.dart';
import 'item_tile.dart';

class CategorySection extends StatefulWidget {
  final String category;
  final List<PackItem> items;
  final bool showCheckboxes;
  final ValueChanged<PackItem>? onItemToggled;
  final ValueChanged<PackItem>? onItemDismissed;
  final VoidCallback? onAddItem;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const CategorySection({
    super.key,
    required this.category,
    required this.items,
    this.showCheckboxes = true,
    this.onItemToggled,
    this.onItemDismissed,
    this.onAddItem,
    this.onReorder,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool _expanded = true;

  int get _checkedCount =>
      widget.items.where((i) => i.isChecked).length;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.onAddItem == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _categoryIcon(widget.category),
                  color: const Color(0xFF00BCD4),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (widget.showCheckboxes)
                  Text(
                    '$_checkedCount/${widget.items.length}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: _buildItemList(),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        if (_expanded && widget.onAddItem != null)
          Padding(
            padding: const EdgeInsets.only(left: 46, bottom: 4),
            child: TextButton.icon(
              onPressed: widget.onAddItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add item', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00BCD4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
          ),
        const Divider(color: Colors.white10, height: 1),
      ],
    );
  }

  Widget _buildItemList() {
    return Column(
      children: widget.items.asMap().entries.map((entry) {
        final item = entry.value;
        return ItemTile(
          key: ValueKey('item_${item.id ?? item.name}_${entry.key}'),
          item: item,
          showCheckbox: widget.showCheckboxes,
          onChanged: widget.showCheckboxes
              ? (_) => widget.onItemToggled?.call(item)
              : null,
          onDismissed: widget.onItemDismissed != null
              ? () => widget.onItemDismissed?.call(item)
              : null,
          dismissKey: ValueKey('dismiss_${item.id ?? item.name}_${entry.key}'),
        );
      }).toList(),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Essentials':
        return Icons.star;
      case 'Clothing':
        return Icons.checkroom;
      case 'Toiletries':
        return Icons.wash;
      case 'Electronics':
        return Icons.devices;
      case 'Documents':
        return Icons.description;
      case 'Other':
        return Icons.inventory_2;
      default:
        return Icons.label;
    }
  }
}
