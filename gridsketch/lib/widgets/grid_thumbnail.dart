import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../data/palettes.dart';

class GridThumbnailPainter extends CustomPainter {
  final Artwork artwork;
  final List<Color> palette;

  GridThumbnailPainter({required this.artwork, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / artwork.gridSize;
    final gridSize = artwork.gridSize;

    // Draw background
    final bgPaint = Paint()..color = const Color(0xFF303030);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw filled cells
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final colorIndex = artwork.getCell(row, col);
        if (colorIndex >= 0 && colorIndex < palette.length) {
          final paint = Paint()..color = palette[colorIndex];
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize,
              cellSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridThumbnailPainter oldDelegate) {
    return artwork.id != oldDelegate.artwork.id ||
        artwork.updatedAt != oldDelegate.artwork.updatedAt;
  }
}

class GridThumbnail extends StatelessWidget {
  final Artwork artwork;
  final double size;

  const GridThumbnail({
    super.key,
    required this.artwork,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final palette = palettes[artwork.paletteIndex].colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        size: Size(size, size),
        painter: GridThumbnailPainter(artwork: artwork, palette: palette),
      ),
    );
  }
}
