import 'dart:io';
import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../services/database_service.dart';
import '../services/measurement_calculator.dart';
import 'measure_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _db = DatabaseService();
  List<Measurement> _measurements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final measurements = await _db.getAllMeasurements();
      if (mounted) {
        setState(() {
          _measurements = measurements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load measurements: $e')),
        );
      }
    }
  }

  Future<void> _deleteMeasurement(Measurement m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Measurement',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this measurement?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && m.id != null) {
      await _db.deleteMeasurement(m.id!);
      _loadMeasurements();
    }
  }

  void _openMeasurement(Measurement m) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MeasureScreen(
          imagePath: m.imagePath,
          referenceType: m.referenceType,
          existingMeasurement: m,
        ),
      ),
    );
    if (result == true) {
      _loadMeasurements();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getSummary(Measurement m) {
    final measureLines = m.lines.where((l) => !l.isReference).toList();
    if (measureLines.isEmpty) return 'No measurements';
    if (measureLines.length == 1 && measureLines.first.realDimensionMm != null) {
      return MeasurementCalculator.formatDimension(
          measureLines.first.realDimensionMm!, m.unit);
    }
    return '${measureLines.length} measurements';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Saved Measurements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _measurements.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No saved measurements yet',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo and measure something!',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadMeasurements,
      color: const Color(0xFFFFC107),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _measurements.length,
        itemBuilder: (context, index) {
          final m = _measurements[index];
          return _buildCard(m);
        },
      ),
    );
  }

  Widget _buildCard(Measurement m) {
    final file = File(m.imagePath);
    final exists = file.existsSync();

    return GestureDetector(
      onTap: () => _openMeasurement(m),
      onLongPress: () => _deleteMeasurement(m),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: exists
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSummary(m),
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (m.note != null && m.note!.isNotEmpty) ...[
                    Text(
                      m.note!,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    _formatDate(m.createdAt),
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.white10,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
      ),
    );
  }
}
