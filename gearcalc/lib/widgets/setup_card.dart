import 'package:flutter/material.dart';
import '../models/drivetrain.dart';

class SetupCard extends StatelessWidget {
  final Drivetrain drivetrain;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;

  const SetupCard({
    super.key,
    required this.drivetrain,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? const Color(0xFF2E3D00)
          : const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFFCDDC39), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFFCDDC39), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      drivetrain.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: Color(0xFFCDDC39), size: 20),
                ],
              ),
              const SizedBox(height: 8),
              _infoRow(
                'Chainrings',
                drivetrain.chainrings.map((c) => '${c}T').join(' / '),
              ),
              const SizedBox(height: 4),
              _infoRow(
                'Cassette',
                '${drivetrain.cassette.first}-${drivetrain.cassette.last} '
                    '(${drivetrain.cassette.length} speed)',
              ),
              const SizedBox(height: 4),
              _infoRow('Wheel', drivetrain.wheelSizeName),
              const SizedBox(height: 4),
              _infoRow(
                'Gears',
                '${drivetrain.chainrings.length * drivetrain.cassette.length} combinations',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
