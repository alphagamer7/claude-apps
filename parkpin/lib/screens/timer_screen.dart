import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/storage_service.dart';

class TimerScreen extends StatefulWidget {
  final StorageService storageService;

  const TimerScreen({super.key, required this.storageService});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  TimerState? _timerState;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  // Duration picker values
  int _selectedHours = 1;
  int _selectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadTimer();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );
    await _notifications.initialize(initSettings);
  }

  void _loadTimer() {
    _timerState = widget.storageService.loadTimer();
    if (_timerState != null && !_timerState!.isExpired) {
      _remaining = _timerState!.remaining;
      _startTicker();
    } else if (_timerState != null && _timerState!.isExpired) {
      // Timer already expired -- clean up
      widget.storageService.clearTimer();
      _timerState = null;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timerState == null) {
        _ticker?.cancel();
        return;
      }
      final remaining = _timerState!.remaining;
      if (remaining == Duration.zero) {
        _ticker?.cancel();
        setState(() => _remaining = Duration.zero);
        _showExpiredDialog();
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  Future<void> _setTimer() async {
    final duration = Duration(
      hours: _selectedHours,
      minutes: _selectedMinutes,
    );
    if (duration.inSeconds == 0) return;

    final endTime = DateTime.now().add(duration);
    await widget.storageService.saveTimer(endTime);

    setState(() {
      _timerState = TimerState(endTime: endTime);
      _remaining = duration;
    });

    _startTicker();
    await _scheduleNotification(duration);
  }

  Future<void> _scheduleNotification(Duration delay) async {
    const androidDetails = AndroidNotificationDetails(
      'parkpin_timer',
      'Parking Timer',
      channelDescription: 'Alerts when your parking meter expires',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Use a short delay approach: schedule a future notification.
    // flutter_local_notifications zonedSchedule requires timezone setup,
    // so we use the show method with a Future.delayed instead for simplicity.
    Future.delayed(delay, () async {
      await _notifications.show(
        0,
        'Parking Timer Expired',
        'Time to move your car!',
        details,
      );
    });
  }

  Future<void> _cancelTimer() async {
    _ticker?.cancel();
    await widget.storageService.clearTimer();
    await _notifications.cancelAll();
    if (mounted) {
      setState(() {
        _timerState = null;
        _remaining = Duration.zero;
      });
    }
  }

  void _showExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Timer Expired'),
        content: const Text('Your parking meter time is up!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelTimer();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveTimer = _timerState != null && !_timerState!.isExpired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Timer'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: hasActiveTimer
              ? _buildCountdownView(theme)
              : _buildPickerView(theme),
        ),
      ),
    );
  }

  Widget _buildCountdownView(ThemeData theme) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'remaining',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 48),
          OutlinedButton.icon(
            onPressed: _cancelTimer,
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            label: const Text(
              'Cancel Timer',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Set Parking Duration',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              _buildNumberPicker(
                value: _selectedHours,
                minValue: 0,
                maxValue: 12,
                label: 'hrs',
                onChanged: (v) => setState(() => _selectedHours = v),
              ),
              const SizedBox(width: 24),
              // Minutes
              _buildNumberPicker(
                value: _selectedMinutes,
                minValue: 0,
                maxValue: 59,
                label: 'min',
                onChanged: (v) => setState(() => _selectedMinutes = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick presets
          Wrap(
            spacing: 8,
            children: [
              _presetChip('30m', 0, 30),
              _presetChip('1h', 1, 0),
              _presetChip('1h 30m', 1, 30),
              _presetChip('2h', 2, 0),
              _presetChip('3h', 3, 0),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (_selectedHours + _selectedMinutes > 0)
                  ? _setTimer
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Timer', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, int hours, int minutes) {
    final isSelected = _selectedHours == hours && _selectedMinutes == minutes;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary.withAlpha(50)
          : null,
      onPressed: () {
        setState(() {
          _selectedHours = hours;
          _selectedMinutes = minutes;
        });
      },
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int minValue,
    required int maxValue,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value < maxValue
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.keyboard_arrow_up, size: 32),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54)),
        IconButton(
          onPressed: value > minValue
              ? () => onChanged(value - 1)
              : null,
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
        ),
      ],
    );
  }
}
