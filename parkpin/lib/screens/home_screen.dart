import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/compass_arrow.dart';
import 'timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  ParkingPin? _pin;
  double? _currentHeading;
  double? _distanceToPin;
  double? _bearingToPin;
  Timer? _locationTimer;
  StreamSubscription<CompassEvent>? _compassSub;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _storageService.init();
    _pin = _storageService.loadPin();

    // Start compass listener
    _compassSub = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _currentHeading = event.heading;
        });
      }
    });

    // Periodically update distance if a pin is saved
    _locationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _updateDistanceAndBearing(),
    );

    // Immediately compute once
    await _updateDistanceAndBearing();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDistanceAndBearing() async {
    if (_pin == null) return;
    final available = await _locationService.isLocationAvailable();
    if (!available) return;

    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;

      final dist = _locationService.distanceBetween(
        pos.latitude,
        pos.longitude,
        _pin!.latitude,
        _pin!.longitude,
      );

      final bearing = _locationService.bearingTo(
        pos.latitude,
        pos.longitude,
        _pin!.latitude,
        _pin!.longitude,
      );

      setState(() {
        _distanceToPin = dist;
        _bearingToPin = bearing;
      });

      // Auto-clear when within 20 metres
      if (dist < 20) {
        _autoClearPin();
      }
    } catch (_) {
      // Location fetch may fail transiently; ignore.
    }
  }

  void _autoClearPin() {
    if (!mounted || _pin == null) return;
    _clearPin();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You reached your car! Pin cleared.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _dropPin() async {
    setState(() => _isSaving = true);

    final granted = await _locationService.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to drop a pin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final pos = await _locationService.getCurrentPosition();
      await _storageService.savePin(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _pin = _storageService.loadPin();
          _isSaving = false;
        });
        _updateDistanceAndBearing();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (photo != null) {
        await _storageService.savePhoto(photo.path);
        if (mounted) {
          setState(() {
            _pin = _storageService.loadPin();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearPin() async {
    await _storageService.clearPin();
    if (mounted) {
      setState(() {
        _pin = null;
        _distanceToPin = null;
        _bearingToPin = null;
      });
    }
  }

  void _openTimer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(storageService: _storageService),
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParkPin'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Parking Timer',
            onPressed: _pin != null ? _openTimer : null,
          ),
        ],
      ),
      body: SafeArea(
        child: _pin == null ? _buildNoPinView() : _buildPinActiveView(),
      ),
    );
  }

  Widget _buildNoPinView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_parking_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 24),
          Text(
            'Where did you park?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button to save your location.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 220,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _dropPin,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.push_pin_rounded, size: 28),
              label: Text(
                _isSaving ? 'Saving...' : 'I Parked Here',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinActiveView() {
    final heading = _currentHeading ?? 0;
    final bearing = _bearingToPin ?? 0;
    // Arrow rotation = bearing to target minus current device heading
    final arrowAngle = bearing - heading;

    final distText = _distanceToPin != null
        ? _locationService.formatDistance(_distanceToPin!)
        : '-- m';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CompassArrow(
            angleDegrees: arrowAngle,
            distanceText: distText,
          ),
          const SizedBox(height: 32),

          // Timestamp
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Parked at'),
              subtitle: Text(_formatTimestamp(_pin!.timestamp)),
            ),
          ),
          const SizedBox(height: 12),

          // Photo
          if (_pin!.photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_pin!.photoPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    _pin!.photoPath != null ? 'Retake Photo' : 'Add Photo',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openTimer,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Set Timer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Clear pin
          TextButton.icon(
            onPressed: _clearPin,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            label: const Text(
              'Clear Pin',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
