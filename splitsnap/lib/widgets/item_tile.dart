import 'package:flutter/material.dart';
import '../models/split_item.dart';

class ItemTile extends StatelessWidget {
  final SplitItem item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        subtitle: item.assignedPerson != null
            ? Text(
                item.assignedPerson!,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 13,
                ),
              )
            : const Text(
                'Tap to assign',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: Colors.grey[850],
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: Colors.white)),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
          ],
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.assignedPerson != null
                ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.assignedPerson != null
                ? Icons.check_circle
                : Icons.receipt_long,
            color: item.assignedPerson != null
                ? const Color(0xFF4CAF50)
                : Colors.grey,
            size: 22,
          ),
        ),
      ),
    );
  }
}
