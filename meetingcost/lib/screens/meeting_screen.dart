import 'dart:async';
import 'package:flutter/material.dart';
import '../services/cost_calculator.dart';
import '../widgets/cost_display.dart';
import 'summary_screen.dart';

class MeetingScreen extends StatefulWidget {
  final int attendeeCount;
  final double hourlyRate;

  const MeetingScreen({
    super.key,
    required this.attendeeCount,
    required this.hourlyRate,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  late final CostCalculator _calculator;

  @override
  void initState() {
    super.initState();
    _calculator = CostCalculator(
      attendeeCount: widget.attendeeCount,
      hourlyRate: widget.hourlyRate,
    );
    _startTimer();
  }

  void _startTimer() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsedSeconds = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _stopwatch.start();
        _isPaused = false;
      } else {
        _stopwatch.stop();
        _isPaused = true;
      }
    });
  }

  double get _currentCost => _calculator.totalCost(_elapsedSeconds);

  String get _formattedTime {
    final total = _stopwatch.elapsed;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Color get _backgroundColor {
    // Shift from green -> yellow -> red as cost increases
    // Thresholds based on cost per person
    final costPerPerson =
        widget.attendeeCount > 0 ? _currentCost / widget.attendeeCount : 0.0;

    if (costPerPerson < 10) {
      // Green zone
      final t = (costPerPerson / 10).clamp(0.0, 1.0);
      return Color.lerp(
        const Color(0xFF1B5E20), // dark green
        const Color(0xFF827717), // dark yellow-green
        t,
      )!;
    } else if (costPerPerson < 30) {
      // Yellow zone
      final t = ((costPerPerson - 10) / 20).clamp(0.0, 1.0);
      return Color.lerp(
        const Color(0xFF827717), // dark yellow-green
        const Color(0xFFBF360C), // dark orange-red
        t,
      )!;
    } else {
      // Red zone
      final t = ((costPerPerson - 30) / 30).clamp(0.0, 1.0);
      return Color.lerp(
        const Color(0xFFBF360C), // dark orange-red
        const Color(0xFFB71C1C), // dark red
        t,
      )!;
    }
  }

  Future<void> _endMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('End Meeting?'),
        content: Text(
          'Total cost so far: \$${_currentCost.toStringAsFixed(2)}\n'
          'Duration: $_formattedTime',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
            ),
            child: const Text('End Meeting'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _stopwatch.stop();
      _ticker?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SummaryScreen(
            attendeeCount: widget.attendeeCount,
            hourlyRate: widget.hourlyRate,
            durationSeconds: _elapsedSeconds,
            totalCost: _currentCost,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _endMeeting();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _backgroundColor.withValues(alpha: 0.6),
              const Color(0xFF121212),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Top bar info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(
                        Icons.people,
                        '${widget.attendeeCount} people',
                      ),
                      _buildInfoChip(
                        Icons.attach_money,
                        '\$${widget.hourlyRate.toStringAsFixed(0)}/hr',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isPaused)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause, color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'PAUSED',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(flex: 2),

                  // Main cost display
                  CostDisplay(cost: _currentCost, fontSize: 72),
                  const SizedBox(height: 8),

                  // Cost per minute
                  Text(
                    '\$${_calculator.costPerMinute.toStringAsFixed(2)} / minute',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Elapsed time
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Controls
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _togglePause,
                            icon: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              size: 24,
                            ),
                            label: Text(
                              _isPaused ? 'Resume' : 'Pause',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _endMeeting,
                            icon: const Icon(Icons.stop, size: 24),
                            label: const Text(
                              'End Meeting',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
