import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/coin_widget.dart';

class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  final Random _random = Random();

  bool _isHeads = true;
  bool _isFlipping = false;
  int _headsCount = 0;
  int _tailsCount = 0;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _flipAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFlipping = false;
          _resultText = _isHeads ? 'HEADS' : 'TAILS';
          if (_isHeads) {
            _headsCount++;
          } else {
            _tailsCount++;
          }
        });
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _flipCoin() {
    if (_isFlipping) return;

    setState(() {
      _isFlipping = true;
      _isHeads = _random.nextBool();
      _resultText = null;
    });

    HapticFeedback.lightImpact();
    _controller.reset();
    _controller.forward();
  }

  void _resetCounter() {
    setState(() {
      _headsCount = 0;
      _tailsCount = 0;
      _resultText = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Flip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
            tooltip: 'Reset counter',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result text
            AnimatedOpacity(
              opacity: _resultText != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _resultText ?? '',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _isHeads
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFC0C0C0),
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Coin
            GestureDetector(
              onTap: _flipCoin,
              child: CoinWidget(
                animation: _flipAnimation,
                isHeads: _isHeads,
                size: 200,
              ),
            ),
            const SizedBox(height: 32),
            // Tap hint
            AnimatedOpacity(
              opacity: _isFlipping ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Tap the coin to flip',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Flip counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CounterChip(
                    label: 'H',
                    count: _headsCount,
                    color: const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 32),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 32),
                  _CounterChip(
                    label: 'T',
                    count: _tailsCount,
                    color: const Color(0xFFC0C0C0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _flipCoin,
        backgroundColor: const Color(0xFFF44336),
        icon: const Icon(Icons.flip),
        label: const Text('Flip!'),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CounterChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
