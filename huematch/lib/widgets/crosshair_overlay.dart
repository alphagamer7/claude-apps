import 'package:flutter/material.dart';

class CrosshairOverlay extends StatelessWidget {
  const CrosshairOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CrosshairPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const crosshairSize = 30.0;
    const gap = 6.0;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw shadow lines first for visibility
    // Horizontal lines
    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx - gap, center.dy),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      shadowPaint,
    );

    // Vertical lines
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy - gap),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + crosshairSize),
      shadowPaint,
    );

    // Draw white lines on top
    // Horizontal lines
    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      paint,
    );

    // Vertical lines
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + crosshairSize),
      paint,
    );

    // Center circle
    canvas.drawCircle(center, 3, shadowPaint);
    canvas.drawCircle(center, 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
