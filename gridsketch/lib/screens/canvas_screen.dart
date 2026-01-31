import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../data/palettes.dart';
import '../services/database_service.dart';
import '../widgets/palette_bar.dart';
import 'gallery_screen.dart';
import 'new_artwork_screen.dart';
import 'export_screen.dart';

class CanvasScreen extends StatefulWidget {
  final Artwork artwork;

  const CanvasScreen({super.key, required this.artwork});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  late Artwork _artwork;
  int _selectedColorIndex = 0;
  bool _eraserSelected = false;
  final List<List<int>> _undoStack = [];
  final DatabaseService _db = DatabaseService();
  final TransformationController _transformController = TransformationController();

  // Track last painted cell to avoid redundant updates during pan
  int? _lastPaintedRow;
  int? _lastPaintedCol;

  @override
  void initState() {
    super.initState();
    _artwork = widget.artwork;
    _pushUndo();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _pushUndo() {
    _undoStack.add(List<int>.from(_artwork.gridData));
    if (_undoStack.length > 21) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.length <= 1) return;
    _undoStack.removeLast();
    setState(() {
      _artwork = _artwork.copyWith(
        gridData: List<int>.from(_undoStack.last),
        updatedAt: DateTime.now(),
      );
    });
  }

  void _paintCell(int row, int col) {
    final colorIndex = _eraserSelected ? -1 : _selectedColorIndex;
    if (_artwork.getCell(row, col) == colorIndex) return;

    setState(() {
      _artwork = _artwork.setCell(row, col, colorIndex);
    });
  }

  void _onCellTap(int row, int col) {
    _pushUndo();
    _paintCell(row, col);
    _lastPaintedRow = null;
    _lastPaintedCol = null;
  }

  void _onCellLongPress(int row, int col) {
    _pushUndo();
    setState(() {
      _artwork = _artwork.setCell(row, col, -1);
    });
  }

  void _onCellPan(int row, int col) {
    if (_lastPaintedRow == row && _lastPaintedCol == col) return;
    if (_lastPaintedRow == null && _lastPaintedCol == null) {
      _pushUndo();
    }
    _lastPaintedRow = row;
    _lastPaintedCol = col;
    _paintCell(row, col);
  }

  (int, int)? _hitTest(Offset globalPosition, BuildContext context) {
    final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final localPos = box.globalToLocal(globalPosition);
    final gridPixelSize = box.size.width;
    final cellSize = gridPixelSize / _artwork.gridSize;

    final col = (localPos.dx / cellSize).floor();
    final row = (localPos.dy / cellSize).floor();

    if (row >= 0 && row < _artwork.gridSize && col >= 0 && col < _artwork.gridSize) {
      return (row, col);
    }
    return null;
  }

  final GlobalKey _gridKey = GlobalKey();

  Future<void> _saveArtwork() async {
    if (_artwork.id == null) {
      final id = await _db.insertArtwork(_artwork);
      setState(() {
        _artwork = _artwork.copyWith(id: id);
      });
    } else {
      await _db.updateArtwork(_artwork);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artwork saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _newArtwork() async {
    final result = await Navigator.push<Artwork>(
      context,
      MaterialPageRoute(builder: (context) => const NewArtworkScreen()),
    );
    if (result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CanvasScreen(artwork: result)),
      );
    }
  }

  Future<void> _openGallery() async {
    final result = await Navigator.push<Artwork>(
      context,
      MaterialPageRoute(builder: (context) => const GalleryScreen()),
    );
    if (result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CanvasScreen(artwork: result)),
      );
    }
  }

  void _openExport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExportScreen(artwork: _artwork)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = palettes[_artwork.paletteIndex].colors;
    final screenSize = MediaQuery.of(context).size;
    final gridDisplaySize = screenSize.width - 16;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_artwork.name} (${_artwork.gridSize}x${_artwork.gridSize})',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.length > 1 ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveArtwork,
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _openExport,
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _openGallery,
            tooltip: 'Gallery',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _newArtwork,
            tooltip: 'New',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 5.0,
                constrained: false,
                child: GestureDetector(
                  onTapDown: (details) {
                    final cell = _hitTest(details.globalPosition, context);
                    if (cell != null) _onCellTap(cell.$1, cell.$2);
                  },
                  onLongPressStart: (details) {
                    final cell = _hitTest(details.globalPosition, context);
                    if (cell != null) _onCellLongPress(cell.$1, cell.$2);
                  },
                  onPanStart: (details) {
                    _lastPaintedRow = null;
                    _lastPaintedCol = null;
                  },
                  onPanUpdate: (details) {
                    final cell = _hitTest(details.globalPosition, context);
                    if (cell != null) _onCellPan(cell.$1, cell.$2);
                  },
                  onPanEnd: (_) {
                    _lastPaintedRow = null;
                    _lastPaintedCol = null;
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: _gridKey,
                      size: Size(gridDisplaySize, gridDisplaySize),
                      painter: _CanvasGridPainter(
                        artwork: _artwork,
                        palette: palette,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PaletteBar(
            colors: palette,
            selectedIndex: _selectedColorIndex,
            eraserSelected: _eraserSelected,
            onColorSelected: (index) {
              setState(() {
                _selectedColorIndex = index;
                _eraserSelected = false;
              });
            },
            onEraserSelected: () {
              setState(() {
                _eraserSelected = true;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _CanvasGridPainter extends CustomPainter {
  final Artwork artwork;
  final List<Color> palette;

  _CanvasGridPainter({required this.artwork, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / artwork.gridSize;
    final gridSize = artwork.gridSize;

    // Draw background
    final bgPaint = Paint()..color = const Color(0xFF303030);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw filled cells
    final cellPaint = Paint();
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final colorIndex = artwork.getCell(row, col);
        if (colorIndex >= 0 && colorIndex < palette.length) {
          cellPaint.color = palette[colorIndex];
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize,
              cellSize,
            ),
            cellPaint,
          );
        }
      }
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF505050)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) {
    return true; // Grid data changes frequently during drawing
  }
}
