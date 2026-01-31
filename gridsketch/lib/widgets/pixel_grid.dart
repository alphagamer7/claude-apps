import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../data/palettes.dart';

class PixelGridPainter extends CustomPainter {
  final Artwork artwork;
  final List<Color> palette;
  final int? highlightRow;
  final int? highlightCol;

  PixelGridPainter({
    required this.artwork,
    required this.palette,
    this.highlightRow,
    this.highlightCol,
  });

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

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF505050)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }

    // Draw highlight
    if (highlightRow != null && highlightCol != null) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
        Rect.fromLTWH(
          highlightCol! * cellSize,
          highlightRow! * cellSize,
          cellSize,
          cellSize,
        ),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PixelGridPainter oldDelegate) {
    return artwork.gridData != oldDelegate.artwork.gridData ||
        highlightRow != oldDelegate.highlightRow ||
        highlightCol != oldDelegate.highlightCol;
  }
}

class PixelGrid extends StatelessWidget {
  final Artwork artwork;
  final double size;
  final Function(int row, int col)? onCellTap;
  final Function(int row, int col)? onCellLongPress;
  final Function(int row, int col)? onCellPan;

  const PixelGrid({
    super.key,
    required this.artwork,
    required this.size,
    this.onCellTap,
    this.onCellLongPress,
    this.onCellPan,
  });

  (int, int)? _positionToCell(Offset localPosition) {
    final cellSize = size / artwork.gridSize;
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();
    if (row >= 0 && row < artwork.gridSize && col >= 0 && col < artwork.gridSize) {
      return (row, col);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = palettes[artwork.paletteIndex].colors;

    return GestureDetector(
      onTapDown: (details) {
        final cell = _positionToCell(details.localPosition);
        if (cell != null && onCellTap != null) {
          onCellTap!(cell.$1, cell.$2);
        }
      },
      onLongPressStart: (details) {
        final cell = _positionToCell(details.localPosition);
        if (cell != null && onCellLongPress != null) {
          onCellLongPress!(cell.$1, cell.$2);
        }
      },
      onPanUpdate: (details) {
        final cell = _positionToCell(details.localPosition);
        if (cell != null && onCellPan != null) {
          onCellPan!(cell.$1, cell.$2);
        }
      },
      child: CustomPaint(
        size: Size(size, size),
        painter: PixelGridPainter(
          artwork: artwork,
          palette: palette,
        ),
      ),
    );
  }
}
