import 'package:flutter/material.dart';

class CostDisplay extends StatelessWidget {
  final double cost;
  final double fontSize;
  final Color? color;

  const CostDisplay({
    super.key,
    required this.cost,
    this.fontSize = 72,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dollars = cost.toStringAsFixed(2);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '\$$dollars',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.white,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: (color ?? Colors.white).withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
