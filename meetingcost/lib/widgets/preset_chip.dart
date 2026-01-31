import 'package:flutter/material.dart';

class PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const PresetChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: const Color(0xFFFF5722).withValues(alpha: 0.15),
      labelStyle: const TextStyle(
        color: Color(0xFFFF5722),
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFFF5722).withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
