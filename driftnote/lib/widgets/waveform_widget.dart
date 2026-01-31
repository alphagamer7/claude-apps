import 'dart:math';
import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;
  final double height;

  const WaveformWidget({
    super.key,
    required this.amplitudes,
    this.color = const Color(0xFF009688),
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _WaveformPainter(
          amplitudes: amplitudes,
          color: color,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _WaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final barWidth = 4.0;
    final gap = 3.0;
    final totalBarWidth = barWidth + gap;
    final maxBars = (size.width / totalBarWidth).floor();
    final barsToShow = min(maxBars, amplitudes.length);

    final startIndex = amplitudes.length > maxBars
        ? amplitudes.length - maxBars
        : 0;

    final centerY = size.height / 2;

    for (int i = 0; i < barsToShow; i++) {
      final amplitude = amplitudes[startIndex + i].clamp(0.0, 1.0);
      final barHeight = max(4.0, amplitude * size.height * 0.8);

      final x = i * totalBarWidth + totalBarWidth / 2;
      final top = centerY - barHeight / 2;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );

      paint.color = color.withValues(alpha: 0.5 + amplitude * 0.5);
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes.length != amplitudes.length ||
        (amplitudes.isNotEmpty &&
            oldDelegate.amplitudes.isNotEmpty &&
            oldDelegate.amplitudes.last != amplitudes.last);
  }
}
