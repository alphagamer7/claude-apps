import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../services/export_service.dart';
import '../widgets/grid_thumbnail.dart';

class ExportScreen extends StatefulWidget {
  final Artwork artwork;

  const ExportScreen({super.key, required this.artwork});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _cellSize = 16;
  bool _exporting = false;
  Uint8List? _previewBytes;

  final List<int> _cellSizeOptions = [8, 16, 32];

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    final bytes = await ExportService.renderToPng(widget.artwork, _cellSize);
    if (mounted) {
      setState(() {
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await ExportService.shareImage(widget.artwork, _cellSize);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportResolution = widget.artwork.gridSize * _cellSize;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Preview
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _previewBytes != null
                        ? Image.memory(
                            _previewBytes!,
                            filterQuality: FilterQuality.none,
                            fit: BoxFit.contain,
                          )
                        : SizedBox(
                            width: 200,
                            height: 200,
                            child: GridThumbnail(
                              artwork: widget.artwork,
                              size: 200,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scale factor
            const Text(
              'Cell Size (pixels)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _cellSizeOptions.map((size) {
                final isSelected = _cellSize == size;
                return GestureDetector(
                  onTap: () {
                    setState(() => _cellSize = size);
                    _generatePreview();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF9C27B0)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF9C27B0) : Colors.white10,
                      ),
                    ),
                    child: Text(
                      '${size}px',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
            Text(
              'Export resolution: ${exportResolution}x$exportResolution',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const SizedBox(height: 24),

            // Export button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(_exporting ? 'Exporting...' : 'Share PNG'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
