import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../data/palettes.dart';

class NewArtworkScreen extends StatefulWidget {
  const NewArtworkScreen({super.key});

  @override
  State<NewArtworkScreen> createState() => _NewArtworkScreenState();
}

class _NewArtworkScreenState extends State<NewArtworkScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Untitled');
  int _selectedGridSize = 16;
  int _selectedPaletteIndex = 0;

  final List<int> _gridSizes = [8, 16, 32];

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final artwork = Artwork(
      name: name,
      gridSize: _selectedGridSize,
      paletteIndex: _selectedPaletteIndex,
    );
    Navigator.pop(context, artwork);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Artwork'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input
            const Text(
              'Name',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF9C27B0)),
                ),
                hintText: 'Enter artwork name',
                hintStyle: const TextStyle(color: Colors.white30),
              ),
            ),

            const SizedBox(height: 32),

            // Grid size picker
            const Text(
              'Grid Size',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _gridSizes.map((size) {
                final isSelected = _selectedGridSize == size;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGridSize = size),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF9C27B0).withValues(alpha: 0.3)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF9C27B0) : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Mini grid preview
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CustomPaint(
                              painter: _GridPreviewPainter(gridSize: size),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${size}x$size',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Palette picker
            const Text(
              'Color Palette',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(palettes.length, (index) {
              final palette = palettes[index];
              final isSelected = _selectedPaletteIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedPaletteIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9C27B0).withValues(alpha: 0.2)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF9C27B0) : Colors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        palette.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: palette.colors.map((color) {
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPreviewPainter extends CustomPainter {
  final int gridSize;

  _GridPreviewPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPreviewPainter oldDelegate) {
    return gridSize != oldDelegate.gridSize;
  }
}
