import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorInfoPanel extends StatelessWidget {
  final Color color;
  final String hex;
  final int red;
  final int green;
  final int blue;
  final double hue;
  final double saturation;
  final double lightness;
  final String nearestName;

  const ColorInfoPanel({
    super.key,
    required this.color,
    required this.hex,
    required this.red,
    required this.green,
    required this.blue,
    required this.hue,
    required this.saturation,
    required this.lightness,
    required this.nearestName,
  });

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $value'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color swatch and name
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nearestName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _copy(context, 'Hex', hex),
                      child: Text(
                        hex,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // RGB and HSL values
          Row(
            children: [
              Expanded(
                child: _ValueTile(
                  label: 'RGB',
                  value: 'R:$red  G:$green  B:$blue',
                  onTap: () => _copy(
                      context, 'RGB', 'rgb($red, $green, $blue)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ValueTile(
                  label: 'HSL',
                  value:
                      'H:${hue.toStringAsFixed(0)}  S:${saturation.toStringAsFixed(0)}  L:${lightness.toStringAsFixed(0)}',
                  onTap: () => _copy(
                    context,
                    'HSL',
                    'hsl(${hue.toStringAsFixed(1)}, ${saturation.toStringAsFixed(1)}%, ${lightness.toStringAsFixed(1)}%)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ValueTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.copy, size: 12, color: Colors.grey[500]),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
