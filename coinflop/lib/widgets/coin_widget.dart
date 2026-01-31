import 'dart:math';
import 'package:flutter/material.dart';

class CoinWidget extends StatelessWidget {
  final Animation<double> animation;
  final bool isHeads;
  final double size;

  const CoinWidget({
    super.key,
    required this.animation,
    required this.isHeads,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final angle = animation.value * pi * 8;
        final showFront = (cos(angle) >= 0);
        final displayHeads = showFront ? isHeads : !isHeads;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: displayHeads
                    ? [
                        const Color(0xFFFFE082),
                        const Color(0xFFFFD700),
                        const Color(0xFFDAA520),
                      ]
                    : [
                        const Color(0xFFE0E0E0),
                        const Color(0xFFC0C0C0),
                        const Color(0xFF9E9E9E),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: (displayHeads
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFC0C0C0))
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayHeads ? 'H' : 'T',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w900,
                      color: displayHeads
                          ? const Color(0xFF8B6914)
                          : const Color(0xFF616161),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    displayHeads ? 'HEADS' : 'TAILS',
                    style: TextStyle(
                      fontSize: size * 0.08,
                      fontWeight: FontWeight.bold,
                      color: displayHeads
                          ? const Color(0xFF8B6914)
                          : const Color(0xFF616161),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
