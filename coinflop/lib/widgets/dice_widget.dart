import 'package:flutter/material.dart';

class DiceWidget extends StatelessWidget {
  final int value;
  final double size;
  final Animation<double>? shakeAnimation;

  const DiceWidget({
    super.key,
    required this.value,
    this.size = 80,
    this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget die = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFF44336).withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DiceFacePainter(value: value, size: size),
      ),
    );

    if (shakeAnimation != null) {
      return AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (context, child) {
          final offset = shakeAnimation!.value;
          return Transform.translate(
            offset: Offset(offset * 3, offset * 2),
            child: Transform.rotate(
              angle: offset * 0.05,
              child: child,
            ),
          );
        },
        child: die,
      );
    }

    return die;
  }
}

class _DiceFacePainter extends CustomPainter {
  final int value;
  final double size;

  _DiceFacePainter({required this.value, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    final dotRadius = size * 0.08;
    final w = canvasSize.width;
    final h = canvasSize.height;

    final positions = _getDotPositions(value, w, h);
    for (final pos in positions) {
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  List<Offset> _getDotPositions(int value, double w, double h) {
    final cx = w / 2;
    final cy = h / 2;
    final left = w * 0.25;
    final right = w * 0.75;
    final top = h * 0.25;
    final bottom = h * 0.75;

    switch (value) {
      case 1:
        return [Offset(cx, cy)];
      case 2:
        return [Offset(left, top), Offset(right, bottom)];
      case 3:
        return [Offset(left, top), Offset(cx, cy), Offset(right, bottom)];
      case 4:
        return [
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ];
      case 5:
        return [
          Offset(left, top),
          Offset(right, top),
          Offset(cx, cy),
          Offset(left, bottom),
          Offset(right, bottom),
        ];
      case 6:
        return [
          Offset(left, top),
          Offset(right, top),
          Offset(left, cy),
          Offset(right, cy),
          Offset(left, bottom),
          Offset(right, bottom),
        ];
      default:
        return [Offset(cx, cy)];
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
