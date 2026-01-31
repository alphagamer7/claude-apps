import 'package:flutter/material.dart';
import '../models/pack_item.dart';

class ItemTile extends StatelessWidget {
  final PackItem item;
  final bool showCheckbox;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onDismissed;
  final Key? dismissKey;

  const ItemTile({
    super.key,
    required this.item,
    this.showCheckbox = true,
    this.onChanged,
    this.onDismissed,
    this.dismissKey,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: showCheckbox
            ? _AnimatedCheckbox(
                value: item.isChecked,
                onChanged: onChanged,
              )
            : const Icon(Icons.drag_handle, color: Colors.white38, size: 20),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            color: item.isChecked ? Colors.white38 : Colors.white,
            fontSize: 15,
            decoration:
                item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
          ),
          child: Text(item.name),
        ),
        trailing: showCheckbox
            ? const Icon(Icons.drag_handle, color: Colors.white24, size: 18)
            : null,
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: dismissKey ?? ValueKey(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.redAccent.withValues(alpha: 0.3),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        child: tile,
      );
    }

    return tile;
  }
}

class _AnimatedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _AnimatedCheckbox({
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF00BCD4) : Colors.transparent,
          border: Border.all(
            color: value ? const Color(0xFF00BCD4) : Colors.white38,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: value ? 1.0 : 0.0,
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
