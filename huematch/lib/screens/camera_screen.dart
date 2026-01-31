import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/color_service.dart';
import '../services/database_service.dart';
import '../models/saved_color.dart';
import '../models/palette.dart';
import '../widgets/crosshair_overlay.dart';
import '../widgets/color_info_panel.dart';
import 'palette_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isFrozen = false;
  bool _isProcessing = false;

  // Current detected color
  int _red = 128;
  int _green = 128;
  int _blue = 128;
  String _hex = '#808080';
  double _hue = 0;
  double _saturation = 0;
  double _lightness = 50;
  String _nearestName = 'Gray';

  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;

    final camera = widget.cameras.first;
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.startImageStream(_processCameraImage);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isFrozen || _isProcessing) return;
    _isProcessing = true;

    List<int>? rgb;

    // iOS uses BGRA format, Android uses YUV
    if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
      rgb = ColorService.extractCenterColorBGRA(image);
    } else {
      rgb = ColorService.extractCenterColor(image);
    }

    if (rgb != null) {
      final hsl = ColorService.rgbToHsl(rgb[0], rgb[1], rgb[2]);
      final hex = ColorService.rgbToHex(rgb[0], rgb[1], rgb[2]);
      final name = ColorService.findNearestName(rgb[0], rgb[1], rgb[2]);

      if (mounted) {
        setState(() {
          _red = rgb![0];
          _green = rgb[1];
          _blue = rgb[2];
          _hex = hex;
          _hue = hsl[0];
          _saturation = hsl[1];
          _lightness = hsl[2];
          _nearestName = name;
        });
      }
    }

    _isProcessing = false;
  }

  void _toggleFreeze() {
    setState(() {
      _isFrozen = !_isFrozen;
    });
  }

  Future<void> _saveColor() async {
    final palettes = await _db.getPalettes();

    if (!mounted) return;

    // Show palette selection dialog
    final selectedPalette = await showDialog<Palette>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Save to Palette', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: palettes.length,
            itemBuilder: (context, index) {
              final palette = palettes[index];
              return ListTile(
                leading: const Icon(Icons.palette, color: Color(0xFFE91E63)),
                title: Text(
                  palette.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${palette.colorIds.length} colors',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                onTap: () => Navigator.pop(context, palette),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPalette == null) return;

    final savedColor = SavedColor(
      hex: _hex,
      red: _red,
      green: _green,
      blue: _blue,
      hue: _hue,
      saturation: _saturation,
      lightness: _lightness,
      nearestName: _nearestName,
      paletteName: selectedPalette.name,
    );

    final colorId = await _db.insertColor(savedColor);
    await _db.addColorToPalette(selectedPalette.id!, colorId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$_nearestName" to ${selectedPalette.name}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE91E63),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = Color.fromARGB(255, _red, _green, _blue);

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                ),
              ),
            ),

          // Crosshair overlay
          const Positioned.fill(
            child: CrosshairOverlay(),
          ),

          // Frozen indicator
          if (_isFrozen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'FROZEN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top action bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.palette, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaletteScreen(),
                  ),
                );
              },
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Action buttons row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Freeze button
                      _ActionButton(
                        icon: _isFrozen ? Icons.play_arrow : Icons.pause,
                        label: _isFrozen ? 'Resume' : 'Freeze',
                        onTap: _toggleFreeze,
                      ),
                      const SizedBox(width: 24),
                      // Save button
                      _ActionButton(
                        icon: Icons.bookmark_add,
                        label: 'Save',
                        onTap: _saveColor,
                        accent: true,
                      ),
                    ],
                  ),
                ),
                // Color info panel
                ColorInfoPanel(
                  color: currentColor,
                  hex: _hex,
                  red: _red,
                  green: _green,
                  blue: _blue,
                  hue: _hue,
                  saturation: _saturation,
                  lightness: _lightness,
                  nearestName: _nearestName,
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent
                  ? const Color(0xFFE91E63)
                  : Colors.black.withValues(alpha: 0.6),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
