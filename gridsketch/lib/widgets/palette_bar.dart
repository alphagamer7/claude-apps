import 'package:flutter/material.dart';

class PaletteBar extends StatelessWidget {
  final List<Color> colors;
  final int selectedIndex;
  final bool eraserSelected;
  final ValueChanged<int> onColorSelected;
  final VoidCallback onEraserSelected;

  const PaletteBar({
    super.key,
    required this.colors,
    required this.selectedIndex,
    required this.eraserSelected,
    required this.onColorSelected,
    required this.onEraserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: colors.length + 1, // +1 for eraser
        itemBuilder: (context, index) {
          if (index == colors.length) {
            // Eraser tool
            return GestureDetector(
              onTap: onEraserSelected,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF303030),
                  border: Border.all(
                    color: eraserSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            );
          }

          final isSelected = !eraserSelected && selectedIndex == index;
          return GestureDetector(
            onTap: () => onColorSelected(index),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[index],
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors[index].withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
