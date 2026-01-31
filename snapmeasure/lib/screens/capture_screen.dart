import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../widgets/reference_chip.dart';
import 'measure_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _selectedReference = 'creditCard';
  bool _showTips = false;
  bool _isCapturing = false;

  final _referenceOptions = [
    {'key': 'creditCard', 'label': 'Credit Card', 'icon': Icons.credit_card},
    {'key': 'coin', 'label': 'US Quarter', 'icon': Icons.monetization_on},
    {'key': 'a4paper', 'label': 'A4 Paper', 'icon': Icons.description},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _isCameraError = true);
        return;
      }
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() => _isCameraError = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final xFile = await _cameraController!.takePicture();
      // Copy to app directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(appDir.path, fileName);
      await File(xFile.path).copy(savedPath);

      if (mounted) {
        _navigateToMeasure(savedPath);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;

    // Copy to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'snap_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = p.join(appDir.path, fileName);
    await File(xFile.path).copy(savedPath);

    if (mounted) {
      _navigateToMeasure(savedPath);
    }
  }

  void _navigateToMeasure(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeasureScreen(
          imagePath: imagePath,
          referenceType: _selectedReference,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SnapMeasure'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Tips',
            onPressed: () => setState(() => _showTips = !_showTips),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Pick from gallery',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview or placeholder
          _buildCameraPreview(),

          // Overlay instructions
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Place reference object and item to measure on a flat surface. Take photo from directly above.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Tips overlay
          if (_showTips) _buildTipsOverlay(),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isCameraError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Camera not available',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the gallery button to pick an image',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFC107)),
      );
    }

    return Center(
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildTipsOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showTips = false),
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC107), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: const Color(0xFFFFC107)),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for Best Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _tipItem(Icons.table_bar, 'Place objects on a flat surface'),
                _tipItem(Icons.arrow_downward,
                    'Take photo from directly overhead'),
                _tipItem(Icons.wb_sunny, 'Ensure good, even lighting'),
                _tipItem(Icons.straighten,
                    'Keep reference object in same plane as item'),
                _tipItem(Icons.zoom_out,
                    'Include full reference object in frame'),
                _tipItem(Icons.contrast,
                    'Use contrasting background for visibility'),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Tap anywhere to close',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reference object picker
          Text(
            'Select Reference Object',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _referenceOptions.map((opt) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ReferenceChip(
                    label: opt['label'] as String,
                    icon: opt['icon'] as IconData,
                    selected: _selectedReference == opt['key'],
                    onTap: () =>
                        setState(() => _selectedReference = opt['key'] as String),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Capture button
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCapturing
                        ? Colors.grey
                        : const Color(0xFFFFC107),
                  ),
                  child: _isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt,
                          color: Colors.black87, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
