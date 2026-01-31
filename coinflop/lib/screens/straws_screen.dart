import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/straw_widget.dart';

class StrawsScreen extends StatefulWidget {
  const StrawsScreen({super.key});

  @override
  State<StrawsScreen> createState() => _StrawsScreenState();
}

class _StrawsScreenState extends State<StrawsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _names = [];
  final Random _random = Random();

  int? _shortStrawIndex;
  bool _isRevealing = false;
  bool _hasDrawn = false;
  List<bool> _revealedStraws = [];
  final List<AnimationController> _revealControllers = [];
  final List<Animation<double>> _revealAnimations = [];

  void _addName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_names.length >= 20) return;

    setState(() {
      _names.add(name);
      _nameController.clear();
      _resetDraw();
    });
  }

  void _removeName(int index) {
    setState(() {
      _names.removeAt(index);
      _resetDraw();
    });
  }

  void _resetDraw() {
    for (final c in _revealControllers) {
      c.dispose();
    }
    _revealControllers.clear();
    _revealAnimations.clear();

    setState(() {
      _shortStrawIndex = null;
      _isRevealing = false;
      _hasDrawn = false;
      _revealedStraws = List.filled(_names.length, false);
    });
  }

  Future<void> _drawStraws() async {
    if (_names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 names to draw straws!')),
      );
      return;
    }

    // Clean up old controllers
    for (final c in _revealControllers) {
      c.dispose();
    }
    _revealControllers.clear();
    _revealAnimations.clear();

    setState(() {
      _isRevealing = true;
      _hasDrawn = false;
      _shortStrawIndex = _random.nextInt(_names.length);
      _revealedStraws = List.filled(_names.length, false);
    });

    // Create animation controllers for each straw
    for (int i = 0; i < _names.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
      _revealControllers.add(controller);
      _revealAnimations.add(animation);
    }

    // Reveal one by one with dramatic pauses
    for (int i = 0; i < _names.length; i++) {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      setState(() {
        _revealedStraws[i] = true;
      });

      _revealControllers[i].forward();
      HapticFeedback.lightImpact();

      // Extra pause before revealing the short straw
      if (i == _shortStrawIndex) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        HapticFeedback.heavyImpact();
      }
    }

    if (!mounted) return;

    setState(() {
      _isRevealing = false;
      _hasDrawn = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _revealControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Straws'),
        actions: [
          if (_hasDrawn)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetDraw,
              tooltip: 'Draw again',
            ),
        ],
      ),
      body: Column(
        children: [
          // Name entry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter a name',
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addName(),
                    enabled: !_isRevealing,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isRevealing ? null : _addName,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          // Names list
          if (_names.isNotEmpty && !_hasDrawn && !_isRevealing)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _names.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_names[index]),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeName(index),
                      backgroundColor: const Color(0xFF2A2A2A),
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          // Draw button
          if (!_hasDrawn && !_isRevealing && _names.length >= 2)
            ElevatedButton.icon(
              onPressed: _drawStraws,
              icon: const Icon(Icons.shuffle),
              label: const Text('Draw Straws!'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
            ),
          if (_isRevealing && !_hasDrawn)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Revealing...',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFF44336),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Result message
          if (_hasDrawn && _shortStrawIndex != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF44336),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SHORT STRAW',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF44336),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _names[_shortStrawIndex!],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Straws display
          if (_isRevealing || _hasDrawn)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_names.length, (index) {
                      final isShort = index == _shortStrawIndex;
                      final isRevealed = _revealedStraws.length > index &&
                          _revealedStraws[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: StrawWidget(
                          name: _names[index],
                          isShort: isShort,
                          isRevealed: isRevealed,
                          revealAnimation:
                              _revealAnimations.length > index
                                  ? _revealAnimations[index]
                                  : null,
                          height: 140,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          // Empty state
          if (_names.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.straighten_outlined,
                      size: 80,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add names to draw straws',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minimum 2 names required',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_names.isNotEmpty && !_hasDrawn && !_isRevealing)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_names.length} player${_names.length == 1 ? '' : 's'} added',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (_names.length < 2) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Add ${2 - _names.length} more to start',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
