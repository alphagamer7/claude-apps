import 'dart:io';
import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../services/measurement_calculator.dart';
import '../services/database_service.dart';
import '../widgets/measurement_painter.dart';

enum MeasurePhase { calibrating, measuring }

class MeasureScreen extends StatefulWidget {
  final String imagePath;
  final String referenceType;
  final Measurement? existingMeasurement;

  const MeasureScreen({
    super.key,
    required this.imagePath,
    required this.referenceType,
    this.existingMeasurement,
  });

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  MeasurePhase _phase = MeasurePhase.calibrating;
  final List<LineSegment> _lines = [];
  Offset? _pendingPoint;
  double _pixelToMmRatio = 0;
  String _unit = 'cm';
  bool _isSaving = false;
  final _noteController = TextEditingController();

  // Image display state
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.existingMeasurement != null) {
      final m = widget.existingMeasurement!;
      _lines.addAll(m.lines);
      _unit = m.unit;
      _noteController.text = m.note ?? '';
      // Find the reference line and recalculate ratio
      final refLine = _lines.where((l) => l.isReference).firstOrNull;
      if (refLine != null) {
        _pixelToMmRatio = MeasurementCalculator.pixelToMmRatio(
          refLine.pixelLength,
          widget.referenceType,
        );
        _phase = MeasurePhase.measuring;
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Offset _toImageCoords(Offset tapPosition) {
    // Convert tap position in the displayed widget to normalized image coordinates
    final renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return tapPosition;

    final localPos = renderBox.globalToLocal(tapPosition);
    return localPos;
  }

  void _onTapDown(TapDownDetails details) {
    final point = _toImageCoords(details.globalPosition);

    if (_pendingPoint == null) {
      // First point of a line
      setState(() => _pendingPoint = point);
    } else {
      // Second point - complete the line
      final start = _pendingPoint!;
      final end = point;

      if (_phase == MeasurePhase.calibrating) {
        // Create reference calibration line
        final pixelLen = MeasurementCalculator.pixelDistance(
          start.dx, start.dy, end.dx, end.dy,
        );
        _pixelToMmRatio = MeasurementCalculator.pixelToMmRatio(
          pixelLen, widget.referenceType,
        );
        final refLine = LineSegment(
          x1: start.dx,
          y1: start.dy,
          x2: end.dx,
          y2: end.dy,
          isReference: true,
          realDimensionMm: MeasurementCalculator.referenceSizes[widget.referenceType],
        );
        setState(() {
          _lines.add(refLine);
          _pendingPoint = null;
          _phase = MeasurePhase.measuring;
        });
      } else {
        // Create measurement line
        final pixelLen = MeasurementCalculator.pixelDistance(
          start.dx, start.dy, end.dx, end.dy,
        );
        final realMm =
            MeasurementCalculator.realDistanceMm(pixelLen, _pixelToMmRatio);
        final measLine = LineSegment(
          x1: start.dx,
          y1: start.dy,
          x2: end.dx,
          y2: end.dy,
          isReference: false,
          realDimensionMm: realMm,
        );
        setState(() {
          _lines.add(measLine);
          _pendingPoint = null;
        });
      }
    }
  }

  void _undoLast() {
    if (_lines.isEmpty) return;
    setState(() {
      final removed = _lines.removeLast();
      _pendingPoint = null;
      if (removed.isReference) {
        _phase = MeasurePhase.calibrating;
        _pixelToMmRatio = 0;
      }
    });
  }

  void _cancelPending() {
    setState(() => _pendingPoint = null);
  }

  void _toggleUnit() {
    setState(() {
      _unit = _unit == 'cm' ? 'inches' : 'cm';
    });
  }

  Future<void> _save() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No measurements to save')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final measurement = Measurement(
        id: widget.existingMeasurement?.id,
        imagePath: widget.imagePath,
        referenceType: widget.referenceType,
        lines: List.from(_lines),
        unit: _unit,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      final db = DatabaseService();
      if (widget.existingMeasurement?.id != null) {
        await db.updateMeasurement(measurement);
      } else {
        await db.insertMeasurement(measurement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement saved!'),
            backgroundColor: Color(0xFFFFC107),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Note', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _noteController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a note for this measurement...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFFFC107)),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done',
                style: TextStyle(color: Color(0xFFFFC107))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refDesc = MeasurementCalculator
            .referenceDescriptions[widget.referenceType] ??
        '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Measure'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Add note',
            onPressed: _showNoteDialog,
          ),
          TextButton(
            onPressed: _toggleUnit,
            child: Text(
              _unit == 'cm' ? 'CM' : 'IN',
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _lines.isNotEmpty || _pendingPoint != null
                ? () {
                    if (_pendingPoint != null) {
                      _cancelPending();
                    } else {
                      _undoLast();
                    }
                  }
                : null,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFC107),
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // Phase indicator
          _buildPhaseBar(refDesc),

          // Image with measurement overlay
          Expanded(
            child: GestureDetector(
              onTapDown: _onTapDown,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.file(
                    File(widget.imagePath),
                    key: _imageKey,
                    fit: BoxFit.contain,
                  ),
                  // Measurement overlay
                  CustomPaint(
                    painter: MeasurementPainter(
                      lines: _lines,
                      pendingPoint: _pendingPoint,
                      isCalibrating: _phase == MeasurePhase.calibrating,
                      unit: _unit,
                      pixelToMmRatio: _pixelToMmRatio,
                    ),
                    size: Size.infinite,
                  ),
                ],
              ),
            ),
          ),

          // Measurement results bar
          if (_lines.where((l) => !l.isReference).isNotEmpty)
            _buildResultsBar(),
        ],
      ),
    );
  }

  Widget _buildPhaseBar(String refDesc) {
    final isCalibrating = _phase == MeasurePhase.calibrating;
    final hasPending = _pendingPoint != null;

    String instruction;
    Color indicatorColor;

    if (isCalibrating) {
      indicatorColor = Colors.blue;
      if (!hasPending) {
        instruction = 'Step 1: Tap the START of your reference object ($refDesc)';
      } else {
        instruction = 'Step 1: Now tap the END of your reference object';
      }
    } else {
      indicatorColor = const Color(0xFFFFC107);
      if (!hasPending) {
        instruction = 'Step 2: Tap START point of what you want to measure';
      } else {
        instruction = 'Step 2: Now tap the END point to complete measurement';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: indicatorColor.withValues(alpha: 0.15),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: indicatorColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
          if (hasPending)
            GestureDetector(
              onTap: _cancelPending,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsBar() {
    final measurementLines = _lines.where((l) => !l.isReference).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Measurements',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ...measurementLines.asMap().entries.map((entry) {
            final idx = entry.key;
            final line = entry.value;
            final dim = line.realDimensionMm;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Line ${idx + 1}: ',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  Text(
                    dim != null
                        ? MeasurementCalculator.formatDimension(dim, _unit)
                        : '...',
                    style: const TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
