import 'package:flutter/material.dart';

class PersonChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PersonChip({
    super.key,
    required this.name,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected
            ? const Color(0xFF4CAF50)
            : Colors.grey[800],
        deleteIcon: onDelete != null
            ? const Icon(Icons.close, size: 16, color: Colors.white54)
            : null,
        onDeleted: onDelete,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
