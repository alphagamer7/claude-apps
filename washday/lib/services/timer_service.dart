import 'dart:async';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../models/cycle_timer.dart';

export '../models/cycle_timer.dart';

class TimerService extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notifications;

  late CycleTimer wash;
  late CycleTimer dry;
  Timer? _ticker;

  TimerService({
    required StorageService storage,
    required NotificationService notifications,
  })  : _storage = storage,
        _notifications = notifications {
    wash = CycleTimer(type: CycleType.wash);
    dry = CycleTimer(type: CycleType.dry);
  }

  Future<void> init() async {
    // Restore wash timer
    if (_storage.getWashRunning()) {
      final startTime = _storage.getWashStartTime();
      final duration = _storage.getWashDurationMs();
      if (startTime != null && duration != null) {
        wash.restore(startTime, duration);
      }
    }

    // Restore dry timer
    if (_storage.getDryRunning()) {
      final startTime = _storage.getDryStartTime();
      final duration = _storage.getDryDurationMs();
      if (startTime != null && duration != null) {
        dry.restore(startTime, duration);
      }
    }

    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;

      if (wash.state == TimerState.running) {
        wash.checkCompletion();
        changed = true;
        if (wash.state == TimerState.done) {
          _storage.clearWashTimerState();
          _storage.incrementWeeklyCount();
        }
      }

      if (dry.state == TimerState.running) {
        dry.checkCompletion();
        changed = true;
        if (dry.state == TimerState.done) {
          _storage.clearDryTimerState();
          _storage.incrementWeeklyCount();
        }
      }

      if (changed) {
        notifyListeners();
      }
    });
  }

  Future<void> startWash() async {
    final durationMinutes = _storage.getWashDuration();
    wash.start(durationMinutes);

    await _storage.saveWashTimerState(
      startTimeMs: wash.startTimeMs!,
      durationMs: wash.durationMs!,
      isRunning: true,
    );

    final playSound = _storage.getNotificationSound();
    await _notifications.scheduleWashDone(
      delay: Duration(minutes: durationMinutes),
      playSound: playSound,
    );

    _startTicker();
    notifyListeners();
  }

  Future<void> startDry() async {
    final durationMinutes = _storage.getDryDuration();
    dry.start(durationMinutes);

    await _storage.saveDryTimerState(
      startTimeMs: dry.startTimeMs!,
      durationMs: dry.durationMs!,
      isRunning: true,
    );

    final playSound = _storage.getNotificationSound();
    await _notifications.scheduleDryDone(
      delay: Duration(minutes: durationMinutes),
      playSound: playSound,
    );

    _startTicker();
    notifyListeners();
  }

  Future<void> resetWash() async {
    wash.reset();
    await _storage.clearWashTimerState();
    await _notifications.cancelWashNotification();
    notifyListeners();
  }

  Future<void> resetDry() async {
    dry.reset();
    await _storage.clearDryTimerState();
    await _notifications.cancelDryNotification();
    notifyListeners();
  }

  void onResume() {
    // Recalculate timer states from persisted timestamps
    if (wash.state == TimerState.running) {
      wash.checkCompletion();
      if (wash.state == TimerState.done) {
        _storage.clearWashTimerState();
        _storage.incrementWeeklyCount();
      }
    }
    if (dry.state == TimerState.running) {
      dry.checkCompletion();
      if (dry.state == TimerState.done) {
        _storage.clearDryTimerState();
        _storage.incrementWeeklyCount();
      }
    }
    notifyListeners();
  }

  int get weeklyCount => _storage.getWeeklyCount();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
