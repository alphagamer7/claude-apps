import 'package:flutter/material.dart';

class PackingProgressBar extends StatelessWidget {
  final int checked;
  final int total;
  final double height;

  const PackingProgressBar({
    super.key,
    required this.checked,
    required this.total,
    this.height = 8.0,
  });

  double get progress => total > 0 ? checked / total : 0.0;

  @override
  Widget build(BuildContext context) {
    final color = _progressColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: height,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$checked / $total packed',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color get _progressColor {
    if (progress >= 1.0) return Colors.greenAccent;
    if (progress >= 0.5) return const Color(0xFF00BCD4);
    return Colors.orangeAccent;
  }
}
