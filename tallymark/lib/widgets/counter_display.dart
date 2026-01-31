import 'package:flutter/material.dart';

class CounterDisplay extends StatefulWidget {
  final int value;
  final Color color;

  const CounterDisplay({
    super.key,
    required this.value,
    required this.color,
  });

  @override
  State<CounterDisplay> createState() => CounterDisplayState();
}

class CounterDisplayState extends State<CounterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void bounce() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        widget.value.toString(),
        style: TextStyle(
          fontSize: _fontSize(widget.value),
          fontWeight: FontWeight.w200,
          color: widget.color,
          height: 1.0,
        ),
      ),
    );
  }

  double _fontSize(int value) {
    final digits = value.abs().toString().length;
    if (digits <= 2) return 160;
    if (digits <= 3) return 130;
    if (digits <= 4) return 100;
    if (digits <= 5) return 80;
    return 60;
  }
}
