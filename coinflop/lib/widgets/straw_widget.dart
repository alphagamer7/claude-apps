import 'package:flutter/material.dart';

class StrawWidget extends StatelessWidget {
  final String name;
  final bool isShort;
  final bool isRevealed;
  final Animation<double>? revealAnimation;
  final double height;

  const StrawWidget({
    super.key,
    required this.name,
    required this.isShort,
    required this.isRevealed,
    this.revealAnimation,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final strawHeight = isShort ? height * 0.5 : height;
    final color = isRevealed && isShort
        ? const Color(0xFFF44336)
        : const Color(0xFFBDBDBD);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name label
        AnimatedOpacity(
          opacity: isRevealed ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isShort && isRevealed
                    ? const Color(0xFFF44336)
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Straw
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          width: 12,
          height: isRevealed ? strawHeight : height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              if (isRevealed && isShort)
                BoxShadow(
                  color: const Color(0xFFF44336).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ],
    );

    if (revealAnimation != null) {
      return AnimatedBuilder(
        animation: revealAnimation!,
        builder: (context, child) {
          return Opacity(
            opacity: revealAnimation!.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - revealAnimation!.value)),
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    return content;
  }
}
