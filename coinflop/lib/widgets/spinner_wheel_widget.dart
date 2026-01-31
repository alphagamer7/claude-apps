import 'dart:math';
import 'package:flutter/material.dart';

class SpinnerWheelWidget extends StatelessWidget {
  final List<String> options;
  final Animation<double> rotationAnimation;
  final int? selectedIndex;
  final double size;

  const SpinnerWheelWidget({
    super.key,
    required this.options,
    required this.rotationAnimation,
    this.selectedIndex,
    this.size = 300,
  });

  static const List<Color> segmentColors = [
    Color(0xFFF44336),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF8BC34A),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arrow indicator at top
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(30, 24),
              painter: _ArrowPainter(),
            ),
          ),
          // Wheel
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: AnimatedBuilder(
              animation: rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: rotationAnimation.value,
                  child: child,
                );
              },
              child: CustomPaint(
                size: Size(size, size),
                painter: _WheelPainter(
                  options: options,
                  colors: segmentColors,
                ),
              ),
            ),
          ),
          // Center circle
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = const Color(0xFFF44336)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheelPainter extends CustomPainter {
  final List<String> options;
  final List<Color> colors;

  _WheelPainter({required this.options, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      final startAngle = i * sweepAngle - pi / 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border between segments
      final borderPaint = Paint()
        ..color = const Color(0xFF1E1E1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw text
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sweepAngle / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '..',
      );
      textPainter.layout(maxWidth: radius * 0.55);
      textPainter.paint(
        canvas,
        Offset(radius * 0.3, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Outer ring
    final outerRingPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.options != options;
  }
}
