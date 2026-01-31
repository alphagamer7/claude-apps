import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  static const List<String> _dayLabels = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  static const List<String> _dayFullLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = selectedDays[index];
        return Tooltip(
          message: _dayFullLabels[index],
          child: FilterChip(
            label: Text(
              _dayLabels[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              final updated = List<bool>.from(selectedDays);
              updated[index] = selected;
              onChanged(updated);
            },
            selectedColor: const Color(0xFF7C4DFF),
            backgroundColor: Colors.grey[850],
            checkmarkColor: Colors.white,
            shape: const CircleBorder(),
            showCheckmark: false,
            padding: const EdgeInsets.all(8),
          ),
        );
      }),
    );
  }
}
