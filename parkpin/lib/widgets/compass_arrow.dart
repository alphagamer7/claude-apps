import 'dart:math';
import 'package:flutter/material.dart';

class CompassArrow extends StatelessWidget {
  /// The angle in degrees the arrow should point (0 = up / north).
  /// This should already be adjusted for device heading, i.e.
  /// bearingToPin - deviceHeading.
  final double angleDegrees;

  /// The distance to the pin, displayed below the arrow.
  final String distanceText;

  const CompassArrow({
    super.key,
    required this.angleDegrees,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angleRadians = angleDegrees * pi / 180;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: angleRadians, end: angleRadians),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value,
                child: child,
              );
            },
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _ArrowPainter(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          distanceText,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'to your car',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final arrowWidth = size.width * 0.25;
    final arrowHeight = size.height * 0.40;

    // Main arrow pointing up
    final arrowPath = Path()
      ..moveTo(cx, cy - arrowHeight) // tip
      ..lineTo(cx + arrowWidth, cy + arrowHeight * 0.3)
      ..lineTo(cx, cy + arrowHeight * 0.1)
      ..lineTo(cx - arrowWidth, cy + arrowHeight * 0.3)
      ..close();

    canvas.drawPath(arrowPath, paint);

    // Outer circle ring
    final ringPaint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.45,
      ringPaint,
    );

    // Small dot at center
    final dotPaint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
