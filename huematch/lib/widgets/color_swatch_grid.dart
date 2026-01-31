import 'package:flutter/material.dart';
import '../models/saved_color.dart';

class ColorSwatchGrid extends StatelessWidget {
  final List<SavedColor> colors;
  final void Function(SavedColor color)? onTap;
  final void Function(SavedColor color)? onLongPress;

  const ColorSwatchGrid({
    super.key,
    required this.colors,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No colors saved yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the camera to capture colors',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final savedColor = colors[index];
        final color = Color.fromARGB(
          255,
          savedColor.red,
          savedColor.green,
          savedColor.blue,
        );

        return GestureDetector(
          onTap: () => onTap?.call(savedColor),
          onLongPress: () => onLongPress?.call(savedColor),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                savedColor.nearestName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                savedColor.hex,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
