import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/palette.dart';
import '../models/saved_color.dart';
import '../widgets/color_swatch_grid.dart';

class PaletteDetailScreen extends StatefulWidget {
  final Palette palette;

  const PaletteDetailScreen({super.key, required this.palette});

  @override
  State<PaletteDetailScreen> createState() => _PaletteDetailScreenState();
}

class _PaletteDetailScreenState extends State<PaletteDetailScreen> {
  final DatabaseService _db = DatabaseService();
  List<SavedColor> _colors = [];
  late Palette _palette;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _palette = widget.palette;
    _loadColors();
  }

  Future<void> _loadColors() async {
    setState(() => _isLoading = true);

    final palette = await _db.getPaletteById(_palette.id!);
    if (palette != null) {
      _palette = palette;
      _colors = await _db.getColorsByIds(palette.colorIds);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showColorDetail(SavedColor color) {
    final displayColor =
        Color.fromARGB(255, color.red, color.green, color.blue);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: displayColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                color.nearestName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                label: 'Hex',
                value: color.hex,
                onCopy: () => _copy('Hex', color.hex),
              ),
              _DetailRow(
                label: 'RGB',
                value: 'rgb(${color.red}, ${color.green}, ${color.blue})',
                onCopy: () => _copy(
                    'RGB', 'rgb(${color.red}, ${color.green}, ${color.blue})'),
              ),
              _DetailRow(
                label: 'HSL',
                value:
                    'hsl(${color.hue.toStringAsFixed(1)}, ${color.saturation.toStringAsFixed(1)}%, ${color.lightness.toStringAsFixed(1)}%)',
                onCopy: () => _copy('HSL',
                    'hsl(${color.hue.toStringAsFixed(1)}, ${color.saturation.toStringAsFixed(1)}%, ${color.lightness.toStringAsFixed(1)}%)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteColor(color);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $value'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteColor(SavedColor color) async {
    if (color.id == null) return;

    await _db.removeColorFromPalette(_palette.id!, color.id!);
    await _db.deleteColor(color.id!);
    _loadColors();
  }

  void _sharePalette() {
    if (_colors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No colors to share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Palette: ${_palette.name}');
    buffer.writeln('---');
    for (final color in _colors) {
      buffer.writeln(
          '${color.nearestName} - ${color.hex} - rgb(${color.red}, ${color.green}, ${color.blue})');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Palette copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFFE91E63),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_palette.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePalette,
            tooltip: 'Share as text',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : ColorSwatchGrid(
              colors: _colors,
              onTap: _showColorDetail,
              onLongPress: _deleteColor,
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18, color: Colors.grey[500]),
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
