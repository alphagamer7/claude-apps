import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/counter.dart';
import '../services/database_service.dart';
import '../widgets/counter_display.dart';
import 'counter_list_screen.dart';
import 'counter_edit_screen.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final DatabaseService _db = DatabaseService();
  List<Counter> _counters = [];
  int _currentIndex = 0;
  final GlobalKey<CounterDisplayState> _displayKey = GlobalKey();

  // Undo support
  int? _lastChange; // +1 or -1

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    final counters = await _db.getCounters();
    setState(() {
      _counters = counters;
      if (_currentIndex >= _counters.length) {
        _currentIndex = _counters.isEmpty ? 0 : _counters.length - 1;
      }
    });
  }

  Counter? get _current =>
      _counters.isNotEmpty && _currentIndex < _counters.length
          ? _counters[_currentIndex]
          : null;

  Color get _counterColor {
    if (_current == null) return const Color(0xFFFF9800);
    return Color(_current!.color);
  }

  Future<void> _increment() async {
    if (_current == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _current!.currentValue++;
      _lastChange = 1;
    });
    _displayKey.currentState?.bounce();
    await _db.updateCounterValue(_current!.id!, _current!.currentValue);
  }

  Future<void> _decrement() async {
    if (_current == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _current!.currentValue--;
      _lastChange = -1;
    });
    _displayKey.currentState?.bounce();
    await _db.updateCounterValue(_current!.id!, _current!.currentValue);
  }

  Future<void> _undo() async {
    if (_current == null || _lastChange == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _current!.currentValue -= _lastChange!;
      _lastChange = null;
    });
    _displayKey.currentState?.bounce();
    await _db.updateCounterValue(_current!.id!, _current!.currentValue);
  }

  Future<void> _openCounterList() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const CounterListScreen()),
    );
    await _loadCounters();
    if (result != null && _counters.isNotEmpty) {
      final idx = _counters.indexWhere((c) => c.id == result);
      if (idx >= 0) {
        setState(() => _currentIndex = idx);
      }
    }
  }

  void _openSettings() {
    if (_current == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CounterEditScreen(counter: _current),
      ),
    ).then((_) => _loadCounters());
  }

  void _selectCounter(int index) {
    setState(() {
      _currentIndex = index;
      _lastChange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_counters.isEmpty) {
      return _buildEmptyState();
    }

    final bgColor = _counterColor.withAlpha(25);

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _increment,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            _decrement();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _current!.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: _counterColor.withAlpha(200),
                        ),
                      ),
                    ),
                    if (_lastChange != null)
                      IconButton(
                        icon: Icon(
                          Icons.undo_rounded,
                          color: Colors.white.withAlpha(120),
                        ),
                        onPressed: _undo,
                        tooltip: 'Undo',
                      ),
                  ],
                ),
              ),

              // Main counter display
              Expanded(
                child: Center(
                  child: CounterDisplay(
                    key: _displayKey,
                    value: _current!.currentValue,
                    color: _counterColor,
                  ),
                ),
              ),

              // Hint text
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Tap to count \u2022 Swipe down to subtract',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(60),
                  ),
                ),
              ),

              // Bottom bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Counter selector chips
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _counters.length,
                            itemBuilder: (context, index) {
                              final c = _counters[index];
                              final isSelected = index == _currentIndex;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _selectCounter(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(c.color).withAlpha(60)
                                          : Colors.white.withAlpha(15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSelected
                                          ? Border.all(
                                              color:
                                                  Color(c.color).withAlpha(120),
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      c.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Color(c.color)
                                            : Colors.white.withAlpha(120),
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Settings / list button
                      IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: Colors.white.withAlpha(120),
                        ),
                        onPressed: _openSettings,
                        tooltip: 'Edit counter',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.list_rounded,
                          color: Colors.white.withAlpha(120),
                        ),
                        onPressed: _openCounterList,
                        tooltip: 'All counters',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 80,
              color: const Color(0xFFFF9800).withAlpha(100),
            ),
            const SizedBox(height: 24),
            const Text(
              'No counters yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tally',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withAlpha(100),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CounterEditScreen(),
                  ),
                );
                _loadCounters();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Counter'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
