import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/spinner_wheel_widget.dart';

class SpinnerScreen extends StatefulWidget {
  const SpinnerScreen({super.key});

  @override
  State<SpinnerScreen> createState() => _SpinnerScreenState();
}

class _SpinnerScreenState extends State<SpinnerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  Animation<double>? _spinAnimation;
  final Random _random = Random();

  final List<String> _options = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  final List<TextEditingController> _textControllers = [];
  bool _isSpinning = false;
  String? _result;
  int? _selectedIndex;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _updateTextControllers();

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _currentAngle = _spinAnimation?.value ?? _currentAngle;
          _calculateResult();
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _updateTextControllers() {
    // Dispose old controllers
    for (final c in _textControllers) {
      c.dispose();
    }
    _textControllers.clear();

    for (int i = 0; i < _options.length; i++) {
      final controller = TextEditingController(text: _options[i]);
      controller.addListener(() {
        _options[i] = controller.text.isEmpty ? 'Option ${i + 1}' : controller.text;
      });
      _textControllers.add(controller);
    }
  }

  void _calculateResult() {
    final normalizedAngle = _currentAngle % (2 * pi);
    final segmentAngle = 2 * pi / _options.length;
    // Arrow is at the top (negative y), and wheel rotates clockwise
    // We need to figure out which segment is at the top
    final adjustedAngle = (2 * pi - normalizedAngle) % (2 * pi);
    final index = (adjustedAngle / segmentAngle).floor() % _options.length;

    setState(() {
      _selectedIndex = index;
      _result = _options[index];
    });
  }

  void _spin() {
    if (_isSpinning) return;
    if (_options.length < 2) return;

    setState(() {
      _isSpinning = true;
      _result = null;
      _selectedIndex = null;
    });

    HapticFeedback.lightImpact();

    // Random number of full rotations (5-10) plus a random final position
    final extraRotations = (_random.nextInt(6) + 5) * 2 * pi;
    final randomAngle = _random.nextDouble() * 2 * pi;
    final targetAngle = _currentAngle + extraRotations + randomAngle;

    _spinAnimation = Tween<double>(
      begin: _currentAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));

    _spinController.reset();
    _spinController.forward();
  }

  void _addOption() {
    if (_options.length >= 12) return;
    setState(() {
      _options.add('Option ${_options.length + 1}');
      _updateTextControllers();
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      _options.removeAt(index);
      _updateTextControllers();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    for (final c in _textControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spinner Wheel'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Wheel
            GestureDetector(
              onTap: _spin,
              child: SpinnerWheelWidget(
                options: _options,
                rotationAnimation: (_spinAnimation != null && _spinController.isAnimating)
                    ? _spinAnimation!
                    : AlwaysStoppedAnimation(_currentAngle),
                selectedIndex: _selectedIndex,
                size: 280,
              ),
            ),
            const SizedBox(height: 16),
            // Result display
            AnimatedOpacity(
              opacity: _result != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF44336),
                    width: 2,
                  ),
                ),
                child: Text(
                  _result ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF44336),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Spin button
            ElevatedButton.icon(
              onPressed: _isSpinning ? null : _spin,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isSpinning ? 'Spinning...' : 'Spin!'),
            ),
            const SizedBox(height: 24),
            // Options editor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Options (${_options.length}/12)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_options.length < 12)
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFFF44336)),
                          onPressed: _addOption,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: SpinnerWheelWidget.segmentColors[
                                  index % SpinnerWheelWidget.segmentColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _textControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Option ${index + 1}',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2A2A2A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                setState(() {
                                  _options[index] = value.isEmpty
                                      ? 'Option ${index + 1}'
                                      : value;
                                });
                              },
                            ),
                          ),
                          if (_options.length > 2)
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              onPressed: () => _removeOption(index),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
