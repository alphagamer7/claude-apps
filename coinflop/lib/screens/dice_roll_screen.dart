import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/dice_widget.dart';

class DiceRollScreen extends StatefulWidget {
  const DiceRollScreen({super.key});

  @override
  State<DiceRollScreen> createState() => _DiceRollScreenState();
}

class _DiceRollScreenState extends State<DiceRollScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final Random _random = Random();

  int _diceCount = 2;
  List<int> _diceValues = [1, 1];
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: -1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: -0.5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.5, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRolling = false;
          _diceValues = List.generate(
            _diceCount,
            (_) => _random.nextInt(6) + 1,
          );
        });
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _rollDice() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    HapticFeedback.lightImpact();
    _shakeController.reset();
    _shakeController.forward();
  }

  void _setDiceCount(int count) {
    setState(() {
      _diceCount = count;
      _diceValues = List.generate(count, (_) => _random.nextInt(6) + 1);
    });
  }

  int get _total => _diceValues.fold(0, (sum, val) => sum + val);

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Roll'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Dice count selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Number of Dice',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final count = index + 1;
                    final isSelected = count == _diceCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _setDiceCount(count),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF44336)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF44336)
                                  : Colors.grey[700]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total: ',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.grey[400],
                  ),
                ),
                Text(
                  '$_total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF44336),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Dice display
          Expanded(
            child: GestureDetector(
              onTap: _rollDice,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(_diceCount, (index) {
                    return DiceWidget(
                      value: index < _diceValues.length
                          ? _diceValues[index]
                          : 1,
                      size: _diceCount <= 2
                          ? 100
                          : _diceCount <= 4
                              ? 80
                              : 70,
                      shakeAnimation: _isRolling ? _shakeAnimation : null,
                    );
                  }),
                ),
              ),
            ),
          ),
          // Tap hint
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Tap anywhere to roll',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _rollDice,
        backgroundColor: const Color(0xFFF44336),
        icon: const Icon(Icons.casino),
        label: const Text('Roll!'),
      ),
    );
  }
}
