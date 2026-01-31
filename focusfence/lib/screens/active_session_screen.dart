import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/timer_display.dart';

class ActiveSessionScreen extends StatefulWidget {
  final String appName;
  final int durationMinutes;

  const ActiveSessionScreen({
    super.key,
    required this.appName,
    required this.durationMinutes,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  Timer? _reminderTimer;
  Timer? _messageTimer;
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  late DateTime _startTime;
  bool _sessionEnded = false;
  int _messageIndex = 0;

  static const List<String> _motivationalMessages = [
    'You\'re doing great! Stay focused.',
    'One thing at a time. You\'ve got this.',
    'Deep work creates deep results.',
    'Stay in the zone. Almost there.',
    'Focus is a superpower. Use it.',
    'Distractions can wait. This can\'t.',
    'You chose to focus. Honor that choice.',
    'Great things take uninterrupted time.',
    'Your future self will thank you.',
    'Keep going. Momentum is building.',
  ];

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTime = DateTime.now();
    _startTimer();
    _startReminderTimer();
    _startMessageRotation();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _completeSession();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _startReminderTimer() {
    // Send a gentle reminder every 5 minutes
    _reminderTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_sessionEnded) {
        _notifications.showReminderNotification(widget.appName);
      }
    });
  }

  void _startMessageRotation() {
    _messageIndex = Random().nextInt(_motivationalMessages.length);
    _messageTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && !_sessionEnded) {
        setState(() {
          _messageIndex =
              (_messageIndex + 1) % _motivationalMessages.length;
        });
      }
    });
  }

  Future<void> _completeSession() async {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _timer?.cancel();
    _reminderTimer?.cancel();
    _messageTimer?.cancel();

    final session = FocusSession(
      appName: widget.appName,
      durationMinutes: widget.durationMinutes,
      startTime: _startTime,
      endTime: DateTime.now(),
      completed: true,
    );
    await _db.insertSession(session);
    await _notifications.showSessionCompleteNotification(widget.appName);

    if (mounted) {
      _showCelebration();
    }
  }

  Future<void> _abandonSession() async {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _timer?.cancel();
    _reminderTimer?.cancel();
    _messageTimer?.cancel();
    await _notifications.cancelAll();

    final session = FocusSession(
      appName: widget.appName,
      durationMinutes: widget.durationMinutes,
      startTime: _startTime,
      endTime: DateTime.now(),
      completed: false,
    );
    await _db.insertSession(session);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Session Complete!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF3F51B5),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: Color(0xFF3F51B5),
            ),
            const SizedBox(height: 16),
            Text(
              'You stayed focused on ${widget.appName} for ${widget.durationMinutes} minutes!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep building that streak.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEndEarly() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'End Early?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This session will be marked as abandoned. Are you sure you want to stop?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Going',
              style: TextStyle(
                color: Color(0xFF3F51B5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abandonSession();
            },
            child: const Text(
              'End Session',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reminderTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmEndEarly();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Timer display
              Expanded(
                child: Center(
                  child: TimerDisplay(
                    remainingSeconds: _remainingSeconds,
                    totalSeconds: _totalSeconds,
                    appName: widget.appName,
                  ),
                ),
              ),

              // Motivational message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  key: ValueKey<int>(_messageIndex),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _motivationalMessages[_messageIndex],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // End early button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _confirmEndEarly,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'End Early',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
