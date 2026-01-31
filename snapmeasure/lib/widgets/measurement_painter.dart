import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../services/measurement_calculator.dart';

class MeasurementPainter extends CustomPainter {
  final List<LineSegment> lines;
  final Offset? pendingPoint;
  final bool isCalibrating;
  final String unit;
  final double pixelToMmRatio;

  MeasurementPainter({
    required this.lines,
    this.pendingPoint,
    this.isCalibrating = true,
    this.unit = 'cm',
    this.pixelToMmRatio = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed lines
    for (final line in lines) {
      _drawLine(canvas, line);
    }

    // Draw pending point
    if (pendingPoint != null) {
      final pointPaint = Paint()
        ..color = isCalibrating
            ? Colors.blue.withValues(alpha: 0.9)
            : Colors.amber.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pendingPoint!, 8, pointPaint);

      // Outer ring
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pendingPoint!, 10, ringPaint);
    }
  }

  void _drawLine(Canvas canvas, LineSegment line) {
    final isRef = line.isReference;
    final color = isRef ? Colors.blue : Colors.amber;

    // Line paint
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final start = Offset(line.x1, line.y1);
    final end = Offset(line.x2, line.y2);

    canvas.drawLine(start, end, linePaint);

    // Endpoint circles
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(start, 6, pointPaint);
    canvas.drawCircle(start, 8, ringPaint);
    canvas.drawCircle(end, 6, pointPaint);
    canvas.drawCircle(end, 8, ringPaint);

    // Dimension label
    String label;
    if (isRef) {
      label = 'REF';
    } else if (line.realDimensionMm != null) {
      label =
          MeasurementCalculator.formatDimension(line.realDimensionMm!, unit);
    } else {
      label = '...';
    }

    final midPoint = Offset((line.x1 + line.x2) / 2, (line.y1 + line.y2) / 2);

    // Draw label background
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 4),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: midPoint.translate(0, -20),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(6),
    );

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.85);
    canvas.drawRRect(bgRect, bgPaint);

    textPainter.paint(
      canvas,
      midPoint.translate(
        -textPainter.width / 2,
        -20 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.pendingPoint != pendingPoint ||
        oldDelegate.isCalibrating != isCalibrating ||
        oldDelegate.unit != unit ||
        oldDelegate.pixelToMmRatio != pixelToMmRatio;
  }
}
